ds = daq.createSession('directsound')
ch = ds.addAnalogOutputChannel('Audio1',1,[])
ds.Rate = ds.StandardSampleRates(7)
fs = ds.Rate
freq = 20000;
len = 2;
data = volume*sin(linspace(0,2*pi*freq,len))';
ds.queueOutputData(sin(100*linspace(0,fs,fs)))
prepare(ds)
ds.startBackground
