// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

primitive _Util
  fun make_bytes[A: Unsigned = Unsigned](input: A): Array[U8] val =>
    """
    Convert the given unsigned integer to an array of bytes (big endian).
    """
    match input
    | let x: U8   => recover [x] end
    | let x: U16  => recover [
                       (x >> 8).u8(),
                       x.u8()] end
    | let x: U32  => recover [
                       (x >> 24).u8(),
                       (x >> 16).u8(),
                       (x >> 8).u8(),
                       x.u8()] end
    | let x: U64  => recover [
                       (x >> 56).u8(),
                       (x >> 48).u8(),
                       (x >> 40).u8(),
                       (x >> 32).u8(),
                       (x >> 24).u8(),
                       (x >> 16).u8(),
                       (x >> 8).u8(),
                       x.u8()] end
    | let x: U128 => recover [
                       (x >> 120).u8(),
                       (x >> 112).u8(),
                       (x >> 104).u8(),
                       (x >> 96).u8(),
                       (x >> 88).u8(),
                       (x >> 80).u8(),
                       (x >> 72).u8(),
                       (x >> 64).u8(),
                       (x >> 56).u8(),
                       (x >> 48).u8(),
                       (x >> 40).u8(),
                       (x >> 32).u8(),
                       (x >> 24).u8(),
                       (x >> 16).u8(),
                       (x >> 8).u8(),
                       x.u8()] end
    else
      recover Array[U8] end
    end
