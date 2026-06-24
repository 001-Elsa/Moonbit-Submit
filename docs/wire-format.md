# MoonPack Wire Format

MoonPack stores each field as a key followed by a value.

```text
key = field_number << 3 | wire_type
```

## Wire Types

| ID | Name | Used for |
| --- | --- | --- |
| 0 | Varint | Bool, Int, Int64, enum |
| 1 | Fixed64 | Double |
| 2 | LengthDelimited | String, Bytes, List, nested message |

## Varint

A varint stores seven payload bits per byte. The most significant bit indicates
whether another byte follows.

## Length-Delimited Values

Length-delimited values are encoded as:

```text
varint byte_length
raw bytes
```

## Compatibility

Decoders must skip fields with unknown field numbers when the wire type is
known. This allows a newer producer to add fields without breaking older
consumers.

