// Parse VXLAN-encapsulated packets into new PCAP
//
// Copyright 2014,2015,2016,2017,2018,2019,2020 Security Onion Solutions, LLC
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

package main
import (
  "os"
  "fmt"
  "github.com/google/gopacket"
  "github.com/google/gopacket/pcap"
  "github.com/google/gopacket/pcapgo"
  "github.com/google/gopacket/layers"
)
var (
  handle   *pcap.Handle
  err      error
  snapshotLen uint32 = 65535
)
func main() {
  if len(os.Args) > 2 {
    srcPCAP := os.Args[1]
    dstPCAP := os.Args[2]

    // Get output file ready
    f, _ := os.Create(dstPCAP)
    w := pcapgo.NewWriter(f)
    w.WriteFileHeader(snapshotLen, layers.LinkTypeEthernet)
    defer f.Close()

    // Read source file
    handle, err = pcap.OpenOffline(srcPCAP)
    defer handle.Close()
    packetSource := gopacket.NewPacketSource(handle, handle.LinkType())
    packetSource.DecodeOptions.Lazy = true
    packetSource.DecodeOptions.NoCopy = true
    for packet := range packetSource.Packets() {
      vxlan := packet.Layer(layers.LayerTypeVXLAN)
      if vxlan != nil {
        vxlan, _ := vxlan.(*layers.VXLAN)
        if vxlan.Payload != nil && len(vxlan.Payload) > 0 {

	  // Define our payload
          payload := vxlan.Payload

	  // Create new packet from our payload
	  depacket := gopacket.NewPacket(payload, layers.LayerTypeEthernet, gopacket.Default)
	  depacket.Metadata().Timestamp = packet.Metadata().Timestamp
	  depacket.Metadata().CaptureLength = len(payload)
	  depacket.Metadata().Length = len(payload)

	  // Panic at the disco if we see errors
	  if err != nil {
            panic(err)
          }

	  // Write previously encapped packet
          w.WritePacket(depacket.Metadata().CaptureInfo, depacket.Data())
        }
      } else {
        // Write non-encapped packet
        w.WritePacket(packet.Metadata().CaptureInfo, packet.Data())
      }
    }
  } else {
    fmt.Println("\nSource/destination PCAP file not provided!\n")
    fmt.Println("Please re-run command like so:\n")
    fmt.Println("./vxlan2pcap <srcPCAP> <dstPCAP\n")
  }
}
