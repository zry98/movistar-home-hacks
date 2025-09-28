package main

import (
	"bufio"
	"bytes"
	"crypto/rand"
	"crypto/sha512"
	"encoding/base64"
	"encoding/hex"
	"flag"
	"fmt"
	"log"
	"mime"
	"mime/quotedprintable"
	"net"
	"net/textproto"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

type Message struct {
	Index int
	Name  string
	Size  int
	Data  []byte
	UID   string
}

func main() {
	dir := flag.String("dir", "./files", "path to the files directory")
	addr := flag.String("addr-pop3", ":8110", "listen address for POP3")
	smtpAddr := flag.String("addr-smtp", ":8025", "listen address for SMTP")
	flag.Parse()

	msgs := buildMessages(*dir)
	log.Printf("Loaded %d files from %s", len(msgs), *dir)

	popLn, err := net.Listen("tcp", *addr)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("POP3 server listening on %s", *addr)

	smtpLn, err := net.Listen("tcp", *smtpAddr)
	if err != nil {
		log.Fatal(err)
	}
	log.Printf("SMTP server listening on %s", *smtpAddr)

	go acceptPOP3(popLn, msgs)
	go acceptSMTP(smtpLn)

	select {}
}

func acceptPOP3(ln net.Listener, msgs []Message) {
	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Println("POP3 accept:", err)
			continue
		}
		go handlePOP3(conn, msgs)
	}
}

func acceptSMTP(ln net.Listener) {
	for {
		conn, err := ln.Accept()
		if err != nil {
			log.Println("SMTP accept:", err)
			continue
		}
		go handleSMTP(conn)
	}
}

func handlePOP3(conn net.Conn, msgs []Message) {
	defer conn.Close()
	br := bufio.NewReader(conn)
	bw := bufio.NewWriter(conn)
	tp := textproto.NewReader(br)

	writeLine(bw, "+OK FileMailServer ready")
	bw.Flush()

	authed := false
	for {
		line, err := tp.ReadLine()
		if err != nil {
			fmt.Println("read err:", err)
			return
		}
		fmt.Println("POP3 >>", line)

		cmd, arg := parseCmd(line)
		switch strings.ToUpper(cmd) {
		case "CAPA":
			writeLine(bw, "+OK")
			writeLine(bw, "USER")
			writeLine(bw, "UIDL")
			writeLine(bw, ".")
		case "USER":
			authed = true // accept any
			writeLine(bw, "+OK")
		case "PASS":
			if authed {
				writeLine(bw, "+OK")
			} else {
				writeLine(bw, "-ERR send USER first")
			}
		case "STAT":
			count, total := 0, 0
			for _, m := range msgs {
				count++
				total += m.Size
			}
			writeLine(bw, fmt.Sprintf("+OK %d %d", count, total))
		case "LIST":
			if arg == "" {
				writeLine(bw, "+OK")
				for _, m := range msgs {
					writeLine(bw, fmt.Sprintf("%d %d", m.Index, m.Size))
				}
				writeLine(bw, ".")
			} else {
				i, err := strconv.ParseInt(arg, 10, 32)
				if err != nil || i < 1 || int(i) > len(msgs) {
					writeLine(bw, "-ERR no such message")
					break
				}
				m := msgs[i-1]
				writeLine(bw, fmt.Sprintf("+OK %d %d", m.Index, m.Size))
			}
		case "RETR":
			i, err := strconv.ParseInt(arg, 10, 32)
			if err != nil || i < 1 || int(i) > len(msgs) {
				writeLine(bw, "-ERR no such message")
				break
			}
			m := msgs[i-1]
			fmt.Printf("Sending file %q (%d bytes)\n", m.Name, m.Size)
			writeLine(bw, fmt.Sprintf("+OK %d octets", m.Size))
			// dot-stuff and write message, then POP3 terminator
			dotStuffAndWrite(bw, m.Data)
			writeLine(bw, ".")
		case "NOOP":
			writeLine(bw, "+OK")
		case "UIDL":
			if arg == "" {
				writeLine(bw, "+OK")
				for _, m := range msgs {
					writeLine(bw, fmt.Sprintf("%d %s", m.Index, m.UID))
				}
				writeLine(bw, ".")
			} else {
				i, err := strconv.ParseInt(arg, 10, 32)
				if err != nil || i < 1 || int(i) > len(msgs) {
					writeLine(bw, "-ERR no such message")
					break
				}
				m := msgs[i-1]
				writeLine(bw, fmt.Sprintf("+OK %d %s", m.Index, m.UID))
			}
		case "QUIT":
			writeLine(bw, "+OK bye")
			bw.Flush()
			return
		default:
			fmt.Printf("unknown POP3 cmd: %q\n", cmd)
			writeLine(bw, "-ERR unknown command")
		}
		bw.Flush()
	}
}

func handleSMTP(conn net.Conn) {
	defer conn.Close()
	br := bufio.NewReader(conn)
	bw := bufio.NewWriter(conn)
	tp := textproto.NewReader(br)

	writeLine(bw, "220 FileMailServer ready")
	bw.Flush()

	for {
		line, err := tp.ReadLine()
		if err != nil {
			fmt.Println("SMTP read err:", err)
			return
		}
		fmt.Println("SMTP >>", line)
		cmd, arg := parseCmd(line)
		switch strings.ToUpper(cmd) {
		case "EHLO", "HELO":
			writeLine(bw, fmt.Sprintf("250 Hello %s", arg))
		default:
			fmt.Printf("unknown SMTP cmd: %q\n", cmd)
			writeLine(bw, "502 Command not implemented")
		}
		bw.Flush()
	}
}

func parseCmd(s string) (cmd, arg string) {
	s = strings.TrimSpace(s)
	if s == "" {
		return "", ""
	}
	parts := strings.SplitN(s, " ", 2)
	cmd = parts[0]
	if len(parts) == 2 {
		arg = strings.TrimSpace(parts[1])
	}
	return
}

func writeLine(w *bufio.Writer, line string) error {
	if _, err := w.WriteString(line); err != nil {
		return err
	}
	if _, err := w.WriteString("\r\n"); err != nil {
		return err
	}
	return nil
}

func buildMessages(dir string) []Message {
	entries, err := os.ReadDir(dir)
	if err != nil {
		log.Fatal(err)
	}
	idx := 1
	msgs := make([]Message, 0, len(entries))
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		fp := filepath.Join(dir, e.Name())
		data, err := os.ReadFile(fp)
		if err != nil {
			log.Printf("skip %s: %v", e.Name(), err)
			continue
		}
		msg := makeRFC822ForFile(e.Name(), data)
		msg = ensureCRLF(msg)
		sum := sha512.Sum512(data)
		m := Message{
			Index: idx,
			Name:  e.Name(),
			Size:  len(msg),
			Data:  msg,
			UID:   hex.EncodeToString(sum[:]),
		}
		msgs = append(msgs, m)
		idx++
	}
	return msgs
}

func makeRFC822ForFile(filename string, fileData []byte) []byte {
	now := time.Now().UTC()
	boundary := randomBoundary()
	subject := fmt.Sprintf("File: %s", filename)
	ct := mime.TypeByExtension(strings.ToLower(filepath.Ext(filename)))
	if ct == "" {
		ct = "application/octet-stream"
	}

	var buf bytes.Buffer
	// Headers
	fmt.Fprintf(&buf, "From: %s\r\n", "fileserver@example.invalid")
	fmt.Fprintf(&buf, "To: %s\r\n", "you@example.invalid")
	fmt.Fprintf(&buf, "Subject: %s\r\n", mime.QEncoding.Encode("utf-8", subject))
	fmt.Fprintf(&buf, "Date: %s\r\n", now.Format(time.RFC1123Z))
	fmt.Fprintf(&buf, "Message-ID: <%s@local>\r\n", boundary[:12])
	fmt.Fprintf(&buf, "MIME-Version: 1.0\r\n")
	fmt.Fprintf(&buf, "Content-Type: multipart/mixed; boundary=%q\r\n", boundary)
	fmt.Fprintf(&buf, "\r\n")

	// Body part (text)
	fmt.Fprintf(&buf, "--%s\r\n", boundary)
	fmt.Fprintf(&buf, "Content-Type: text/plain; charset=utf-8\r\n")
	fmt.Fprintf(&buf, "Content-Transfer-Encoding: quoted-printable\r\n\r\n")
	qp := quotedprintable.NewWriter(&buf)
	qp.Write([]byte("Hello from FileMailServer, a file is attached.\r\n"))
	qp.Close()
	fmt.Fprintf(&buf, "\r\n")

	// Attachment
	fmt.Fprintf(&buf, "--%s\r\n", boundary)
	fmt.Fprintf(&buf, "Content-Type: %s\r\n", ct)
	fmt.Fprintf(&buf, "Content-Disposition: attachment; filename=%q\r\n", filename)
	fmt.Fprintf(&buf, "Content-Transfer-Encoding: base64\r\n\r\n")
	b64Chunk(&buf, fileData)
	fmt.Fprintf(&buf, "\r\n--%s--\r\n", boundary)

	return buf.Bytes()
}

func randomBoundary() string {
	var b [12]byte
	_, _ = rand.Read(b[:])
	return "BOUNDARY-" + hex.EncodeToString(b[:])
}

func b64Chunk(w *bytes.Buffer, data []byte) {
	enc := base64.StdEncoding.EncodeToString(data)
	// wrap at 76 chars per MIME spec
	for i := 0; i < len(enc); i += 76 {
		j := i + 76
		if j > len(enc) {
			j = len(enc)
		}
		w.WriteString(enc[i:j])
		w.WriteString("\r\n")
	}
}

// Convert lone \n to \r\n (and \r\n intact) so sizes/terminators work right.
func ensureCRLF(b []byte) []byte {
	b = bytes.ReplaceAll(b, []byte("\r\n"), []byte("\n"))
	b = bytes.ReplaceAll(b, []byte("\r"), []byte("\n"))
	return bytes.ReplaceAll(b, []byte("\n"), []byte("\r\n"))
}

// Dot-stuff lines starting with '.' and stream out.
func dotStuffAndWrite(bw *bufio.Writer, msg []byte) {
	sc := bufio.NewScanner(bytes.NewReader(msg))
	// increase Scanner buffer for long MIME lines
	buf := make([]byte, 0, 1024*1024)
	sc.Buffer(buf, 10*1024*1024)
	for sc.Scan() {
		line := sc.Text()
		if strings.HasPrefix(line, ".") {
			bw.WriteString("." + line + "\r\n")
		} else {
			bw.WriteString(line + "\r\n")
		}
	}
}
