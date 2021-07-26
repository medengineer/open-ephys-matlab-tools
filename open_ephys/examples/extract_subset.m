clear all; close all; clc;

%Define the path to the data location
DATA_PATH = 'C:\Users\Pavel\OneDrive\Documents\Open Ephys\SampleNPXRecording - edited';

%Define sample rates
AP_SAMPLE_RATE = 30000;
LFP_SAMPLE_RATE = 2500;

%Create a session object using the data path
session = Session(DATA_PATH);

%Get the record node object
node = session.recordNodes{1};

%Get the recoridng object
recording = node.recordings{1};

%Get a list of recorded processors w/ continuous data
processors = recording.continuous.keys();

%AP data is in first processor, LFP data is in second processor
AP_data = recording.continuous(processors{1});
LFP_data = recording.continuous(processors{2});

%Get the total recording time in seconds:
total_recording_time = length(AP_data.timestamps) / AP_SAMPLE_RATE;

%Define desired start/stop times for extraction 
start_time = 0.25*total_recording_time;
stop_time = 0.75*total_recording_time;

%Find the corresponding start/stop samples
AP_start_sample = round(start_time * AP_SAMPLE_RATE);
AP_stop_sample = round(stop_time * AP_SAMPLE_RATE);

LFP_start_sample = round(start_time * LFP_SAMPLE_RATE);
LFP_stop_sample = round(stop_time * LFP_SAMPLE_RATE);

%Get samples/timestamps between start/stop samples
AP_data_subset_samples = AP_data.samples(:,AP_start_sample:AP_stop_sample);
AP_data_subset_timestamps = AP_data.timestamps(AP_start_sample:AP_stop_sample);

LFP_data_subset_samples = LFP_data.samples(:,LFP_start_sample:LFP_stop_sample);
LFP_data_subset_timestamps = LFP_data.timestamps(LFP_start_sample:LFP_stop_sample);

%Generate AP data subset
new_AP_data = AP_data;
new_AP_data.samples = AP_data_subset_samples;
new_AP_data.timestamps = AP_data_subset_timestamps;

%Generate LFP data subset
new_LFP_data = LFP_data;
new_LFP_data.samples = LFP_data_subset_samples;
new_LFP_data.timestamps = LFP_data_subset_timestamps;

%Check that the new subset recording time makes sense
new_recording_time = length(new_AP_data.timestamps) / AP_SAMPLE_RATE;

%Write extracted AP data
out = { 'continuous', ['Neuropix-PXI-', processors{1}] };
for k = 1:length(out)
    subdir = fullfile(out{1:k}); mkdir(subdir);
end
writeDAT(new_AP_data.samples, fullfile('continuous', ['Neuropix-PXI-', processors{1}], 'continuous.dat'));
writeNPY(new_AP_data.timestamps, fullfile('continuous', ['Neuropix-PXI-', processors{1}], 'timestamps.npy'));

%Write extracted LFP data
subdir = fullfile('continuous', ['Neuropix-PXI-', processors{2}]); 
mkdir(subdir);
writeDAT(new_LFP_data.samples, fullfile('continuous', ['Neuropix-PXI-', processors{2}], 'continuous.dat'));
writeNPY(new_LFP_data.timestamps, fullfile('continuous', ['Neuropix-PXI-', processors{2}], 'timestamps.npy'));

%Extract AP event data
AP_event_data = recording.ttlEvents(processors{1});

idx = (AP_event_data.timestamp >= AP_start_sample) & (AP_event_data.timestamp <= AP_stop_sample);

new_AP_event_data = DataFrame(...
    AP_event_data.channel(idx),...
    AP_event_data.timestamp(idx),...
    AP_event_data.processorId(idx),...
    AP_event_data.subprocessorId(idx),...
    AP_event_data.state(idx), ...
    'VariableNames', {'channel','timestamp','processorId','subprocessorId', 'state'});

%Write extracted AP event data
out = { 'events', ['Neuropix-PXI-', processors{1}], 'TTL_1' };
for k = 1:length(out)
    subdir = fullfile(out{1:k}); mkdir(subdir);
end
writeNPY(AP_event_data.channel(idx), fullfile('events', ['Neuropix-PXI-', processors{1}], 'TTL_1', 'channels.npy'));
writeNPY(AP_event_data.timestamp(idx), fullfile('events', ['Neuropix-PXI-', processors{1}], 'TTL_1', 'timestamps.npy'));
writeNPY(AP_event_data.state(idx), fullfile('events', ['Neuropix-PXI-', processors{1}], 'TTL_1', 'channel_states.npy'));

%Extract LFP event data
LFP_event_data = recording.ttlEvents(processors{2});

idx = (LFP_event_data.timestamp >= LFP_start_sample) & (LFP_event_data.timestamp <= LFP_stop_sample);

new_LFP_event_data = DataFrame(...
    LFP_event_data.channel(idx),...
    LFP_event_data.timestamp(idx),...
    LFP_event_data.processorId(idx),...
    LFP_event_data.subprocessorId(idx),...
    LFP_event_data.state(idx), ...
    'VariableNames', {'channel','timestamp','processorId','subprocessorId', 'state'});

%Write extracted LFP event data
subdir = fullfile('events', ['Neuropix-PXI-', processors{2}], 'TTL_2'); 
mkdir(subdir);
writeNPY(LFP_event_data.channel(idx), fullfile('events', ['Neuropix-PXI-', processors{2}], 'TTL_2', 'channels.npy'));
writeNPY(LFP_event_data.timestamp(idx), fullfile('events', ['Neuropix-PXI-', processors{2}], 'TTL_2', 'timestamps.npy'));
writeNPY(LFP_event_data.state(idx), fullfile('events', ['Neuropix-PXI-', processors{2}], 'TTL_2', 'channel_states.npy'));