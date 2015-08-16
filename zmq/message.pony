// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

use zmtp = "zmtp"

type Message is zmtp.Message
type MessageFrame is zmtp.Frame
type _MessageParser is zmtp.MessageParser
type _MessageWriteTransform is zmtp.MessageWriteTransform
