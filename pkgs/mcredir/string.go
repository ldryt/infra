package main

import "io"

// https://wiki.vg/Protocol#Type:String

func ReadString(r io.Reader) (value string, err error) {
	var len int32
	var buf []byte

	len, err = ReadVarInt(r)
	if err != nil {
		return "", err
	}

	buf = make([]byte, len)

	_, err = r.Read(buf)
	if err != nil {
		return "", err
	}

	return string(buf), nil
}

func WriteString(w io.Writer, value string) (err error) {
	var len int = len(value)

	err = WriteVarInt(w, int32(len))
	if err != nil {
		return err
	}

	_, err = w.Write([]byte(value))
	if err != nil {
		return err
	}

	return nil
}
