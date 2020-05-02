# Parse VXLAN-encapsulated packets into new PCAP
#
# Copyright 2014,2015,2016,2017,2018,2019,2020 Security Onion Solutions, LLC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Pre-reqs:
# pip3 install scapy
# Example VXLAN PCAP: https://github.com/the-tcpdump-group/tcpdump/raw/master/tests/vxlan.pcap

import sys, getopt
from scapy.all import *

def write(pkt):
    wrpcap(outputfile, pkt, append=True)

def main(argv):
    global outputfile
    inputfile = ''
    outputfile = ''
    try:
        opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
    except getopt.GetoptError:
        print ('test.py -i <inputfile> -o <outputfile>')
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print ('test.py -i <inputfile> -o <outputfile>')
            sys.exit()
        elif opt in ("-i", "--ifile"):
            inputfile = arg
        elif opt in ("-o", "--ofile"):
            outputfile = arg

    print("\nConverting packets from " + inputfile + " into " + outputfile + "...\n")

    # Read in packets (use PcapReader so we don't have to load large PCAPs in memory)
    with PcapReader(inputfile) as pkts:
        for pkt in pkts:
            # Write VXLAN payload if match
            if pkt.haslayer(VXLAN):
                try:
                    write(pkt[VXLAN].payload)
                except:
                    print("VXLAN encapsulated packet not found.")
            # Otherwise, just write the packet
            else:
                print("No VXLAN packet to convert...writing original packet.")
                try:
                    write(pkt)
                except:
                    print("Couldn't write packet!")

    print("Done!")
if __name__ == "__main__":
   main(sys.argv[1:])
