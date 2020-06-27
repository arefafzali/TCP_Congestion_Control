import matplotlib.pyplot as plt
import subprocess
import multiprocessing as mp
import sys

def corresponding_send_idx(time, source_node):
	f = open("trace.tr", "r")
	lines = f.readlines()
	for l in lines:
		l = l.split()
		if(l[-2] != "maxseq_"):
			continue
		if l[0] == time:
			if l[1] == source_node:
				return l[-1]
	return False

def process_trace_var(trace_var_):
	x = [[], []]
	y = [[], []]
	f = open("trace.tr", "r")
	lines = f.readlines()
	num_send_pkt = [0, 0]
	for line_num, l in enumerate(lines):
		l = l.split()
		if l[0] == "-":
			if l[2] == "2":
				num_send_pkt[0] += 1
			elif l[2] == "3":
				num_send_pkt[1] += 1

		trace_var = l[-2]
		if trace_var == trace_var_:
			num_tcp = int(l[1]) - 2
			x_trace_val = float(l[0])
			y_trace_val = float(l[-1])
			if y_trace_val >= 0 :
					if trace_var == "ack_":
						if num_send_pkt[num_tcp] != 0:
							x[num_tcp].append(x_trace_val)
							y[num_tcp].append((y_trace_val) / num_send_pkt[num_tcp])
					else:
						x[num_tcp].append(x_trace_val)
						y[num_tcp].append(y_trace_val)

		#if line_num >= 20000:
			#break
	f.close()
	return [x, y]

def plot_output(x, y, l, var):
	# plt.figure()
	plt.plot(x[0], y[0], label="tcp_1 "+var)
	plt.plot(x[1], y[1], label="tcp_2 "+var)
	plt.legend(loc="best")
	plt.title(l)
	if var =="goodput":
		plt.ylim([-0.2, 1])

def count_drop_pkt():
	num_drop = [0, 0]
	y_num_drop = [[], []]
	x_num_drop = [[], []]
	f = open("trace.tr", "r")
	lines = f.readlines()
	for l in lines:
		l = l.split()
		if l[0] == "d":
			if l[7] == "1":
				num_drop[0] += 1
				t = float(l[1])
				x_num_drop[0].append(t)
				y_num_drop[0].append(num_drop[0]/t)
			elif l[7] == "2":
				num_drop[1] += 1
				t = float(l[1])
				x_num_drop[1].append(t)
				y_num_drop[1].append(num_drop[1]/t)
			else :
				print("l[7]={}, Number of Flows is greater than 2".format(l[7]))
				sys.exit(1)
	return num_drop, x_num_drop, y_num_drop

if __name__ == "__main__":
	pool = mp.Pool(processes=10)

	#for i in range(2):
	print("TCP New-Reno:")
	subprocess.run(["ns", sys.argv[1]])
	data1 = pool.map(process_trace_var, ["cwnd_", "ack_", "rtt_"])
	num_drop, x_num_drop, y_num_drop = count_drop_pkt()	
	plot_output(x_num_drop, y_num_drop, "DROP_RATE_NEW_RENO", "drop_rate")
	print("Num Drops For TCP_1 = {}".format(num_drop[0]))
	print("Num Drops For TCP_2 = {}\n".format(num_drop[1]))

	print("TCP Tahoe:")
	subprocess.run(["ns", sys.argv[2]])
	data2 = pool.map(process_trace_var, ["cwnd_", "ack_", "rtt_"])
	num_drop, x_num_drop, y_num_drop = count_drop_pkt()	
	plot_output(x_num_drop, y_num_drop, "DROP_RATE_Tahoe", "drop_rate")
	print("Num Drops For TCP_1 = {}".format(num_drop[0]))
	print("Num Drops For TCP_2 = {}\n".format(num_drop[1]))

	print("TCP Vegas:")
	subprocess.run(["ns", sys.argv[3]])
	data3 = pool.map(process_trace_var, ["cwnd_", "ack_", "rtt_"])
	num_drop, x_num_drop, y_num_drop = count_drop_pkt()	
	plot_output(x_num_drop, y_num_drop, "DROP_RATE_Vegas", "drop_rate")
	print("Num Drops For TCP_1 = {}".format(num_drop[0]))
	print("Num Drops For TCP_2 = {}\n".format(num_drop[1]))
	
	pool.close()
	plt.figure()
	plot_output(data1[0][0], data1[0][1], "CWND", "Newreno cwnd")
	plot_output(data2[0][0], data2[0][1], "CWND", "Tahoe cwnd")
	plot_output(data3[0][0], data3[0][1], "CWND", "Vegas cwnd")
	print("CWND plot is complete")
	plt.figure()
	plot_output(data1[1][0], data1[1][1], "Good Put Ratio", "Newreno goodput")
	plot_output(data2[1][0], data2[1][1], "Good Put Ratio", "Tahoe goodput")
	plot_output(data3[1][0], data3[1][1], "Good Put Ratio", "Vegas goodput")
	print("Good put ratio plot is complete")
	plt.figure()
	plot_output(data1[2][0], data1[2][1], "RTT", "Newreno rtt")
	plot_output(data2[2][0], data2[2][1], "RTT", "Tahoe rtt")
	plot_output(data3[2][0], data3[2][1], "RTT", "Vegas rtt")
	print("RTT plot is complete")
	
	plt.show()
