#Create sim obj
set ns [new Simulator]
set random_delay [expr {5+(rand()*20)}]
puts $random_delay

#Color of data flow between server 1 and 5
$ns color 1 Blue
#Color of data flow between server 2 and 6
$ns color 2 Red

#Create Nam file
set nf [open out.nam w]
$ns namtrace-all $nf

#Create Trace file
set tracefile [open trace.tr w]
$ns trace-all $tracefile

#Define a 'finish' procedure
proc finish {} {
        global ns nf tracefile tcp_1 tcp_2 
        $ns flush-trace
        #Close the NAM trace file
        close $nf
	set tcp_tick_1 [$tcp_1 set tcpTick_]
	set window_1 [$tcp_1 set window_]
	set last_ack_1 [$tcp_1 set ack_]
	set last_seq_1 [$tcp_1 set maxseq_]

	set tcp_tick_2 [$tcp_2 set tcpTick_]
	set window_2 [$tcp_2 set window_]
	set last_ack_2 [$tcp_2 set ack_]
	set last_seq_2 [$tcp_2 set maxseq_]
        #Execute NAM on the trace file
        #exec nam out.nam &
	puts "tcp_1 window size: $window_1, tcp_2 window size: $window_2"
	puts "tcp_tick_1 :$tcp_tick_1 last_ack_1 :$last_ack_1 - last_seq_1 :$last_seq_1" 
	puts "tcp_tick_2 :$tcp_tick_2 last_ack_2 :$last_ack_2 - last_seq_2 :$last_seq_2"
	close $tracefile
        exit 0
}

#define routers
set r1 [$ns node]
set r2 [$ns node]
set node_1 [$ns node]
set node_2 [$ns node]
set node_3 [$ns node]
set node_4 [$ns node]

#Set First TCP Connection
set tcp_1 [new Agent/TCP]
$tcp_1 set class_ 1
$tcp_1 set fid_ 1
$tcp_1 set packetSize_ 960

#Set Sink for TCP_1
set sink_1 [new Agent/TCPSink]

#Set Second TCP Connection
set tcp_2 [new Agent/TCP]
$tcp_2 set class_ 2
$tcp_2 set fid_ 2
$tcp_2 set packetSize_ 960

#Set Sink for TCP_2
set sink_2 [new Agent/TCPSink]


#Set FTP
set ftp_1 [new Application/FTP]
#$ftp_1 set type_ FTP
set ftp_2 [new Application/FTP]
#$ftp_2 set type_ FTP


#Set Connection between Nodes
$ns duplex-link $r1 $r2 100kb 1ms DropTail
$ns duplex-link $node_1 $r1 100Mb 5ms DropTail
$ns duplex-link $node_2 $r1 100Mb ${random_delay}ms DropTail
$ns duplex-link $r2 $node_3 100Mb 5ms DropTail
$ns duplex-link $r2 $node_4 100Mb ${random_delay}ms DropTail

#Set Links between TCP Connection and nodes
$ns attach-agent $node_1 $tcp_1
$ns attach-agent $node_2 $tcp_2
$ns attach-agent $node_3 $sink_1
$ns attach-agent $node_4 $sink_2

#Set Link between TCP connection and FTP
$ftp_1 attach-agent $tcp_1
$ftp_2 attach-agent $tcp_2

#Connect TCP pair
$ns connect $tcp_1 $sink_1
$ns connect $tcp_2 $sink_2

#Trace TCP Var
# Let's trace some variables
$tcp_1 attach $tracefile
$tcp_2 attach $tracefile

$tcp_1 tracevar cwnd_
$tcp_1 tracevar ssthresh_
$tcp_1 tracevar ack_
$tcp_1 tracevar maxseq_
$tcp_1 tracevar rtt_

$tcp_2 tracevar cwnd_
$tcp_2 tracevar ssthresh_
$tcp_2 tracevar ack_
$tcp_2 tracevar maxseq_
$tcp_2 tracevar rtt_

#$sink_1 tracevar cwnd_
#$sink_1 tracevar ssthresh_
#$sink_1 tracevar ack_
#$sink_1 tracevar maxseq_


#$sink_2 tracevar cwnd_
#$sink_2 tracevar ssthresh_
#$sink_2 tracevar ack_
#$sink_2 tracevar maxseq_


#Set Queue Size of Links
$ns queue-limit $r1 $r2 10
#Give node position (for NAM)
$ns duplex-link-op $node_1 $r1 orient right-down
$ns duplex-link-op $node_2 $r1 orient right-up
$ns duplex-link-op $r1 $r2 orient right
$ns duplex-link-op $r2 $node_3 orient right-up
$ns duplex-link-op $r2 $node_4 orient right-down

#Monitor the queue for link (node_2-node_3). (for NAM)
$ns duplex-link-op $r2 $r1 queuePos 0.5


#Schedule FTP
$ns at 1 "$ftp_1 start"
$ns at 1 "$ftp_2 start"
$ns at 990 "$ftp_1 stop"
$ns at 990 "$ftp_2 stop"

#Detach tcp and sink agents (not really necessary)
$ns at 999 "$ns detach-agent $node_1 $tcp_1 ; $ns detach-agent $node_2 $tcp_2 ; $ns detach-agent $node_3 $sink_1 ; $ns detach-agent $node_4 $sink_2"

#Call the finish procedure after 5 seconds of simulation time
$ns at 1000 "finish"

#Run the simulation
$ns run


