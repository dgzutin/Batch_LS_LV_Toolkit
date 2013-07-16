/*This is a test Script that simulates the submission of an experiment execution request */

INSERT INTO ELVIS_LS.dbo.JobRecord([provider_id], [broker_assigned_id], [priority], [job_status], [submit_time], [exec_time], [end_time], [exec_elapsed], [job_elapsed], [est_exec_time], [queue_at_insert], [datapoints], [setup_used], [lab_config_at_exec], [experiment_vector],[error_occurred], [downloaded])
VALUES (
'22',
'22',
'0',
'QUEUED',
'2009-05-26 11:35:51.090',
'2009-05-26 11:35:55.123',
'2009-05-26 11:36:02.700',
'7',
'11',
'5',
'1',
'0',
'1', 
'<?xml version=''1.0'' encoding=''utf-8'' standalone=''no'' ?><!DOCTYPE labConfiguration SYSTEM ''http://ilab-labview.mit.edu/labserver/xml/labConfiguration.dtd''><labConfiguration lab=''MIT ELVIS Weblab'' specversion=''0.1''><setup id=''1''><name>Circuit 01</name><description>Circuit 01</description><imageURL></imageURL><terminal instrumentType=''FGEN'' instrumentNumber=''1''><label>FGEN</label><pixelLocation><x>15</x><y>15</y></pixelLocation></terminal><terminal instrumentType=''SCOPE'' instrumentNumber=''2''><label>SCOPE</label><pixelLocation><x>5</x><y>5</y></pixelLocation></terminal></setup><imageData url=''''></imageData></labConfiguration>',
'<?xml version="1.0" encoding="utf-8" standalone="no" ?><!DOCTYPE experimentSpecification SYSTEM "http://olid.mit.edu/xml/experimentSpecification.dtd"><experimentSpecification lab="MIT NI-ELVIS Weblab" specversion="0.1"><setupID>1</setupID><PACString>{?xml version="1.0"?}{PacDesignData}{DocFmtVersion}1{/DocFmtVersion}{DeviceType}ispPAC10{/DeviceType}{FuseMap}00000000000000000011000000000000000000000000110000000000000000000000001100000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000{/FuseMap}{SummaryInformation}{Title}{/Title}{Subject}{/Subject}{Author}CTI{/Author}{Keywords}ispPAC10{/Keywords}{Comments}{![CDATA[]]}{/Comments}{/SummaryInformation}{/PacDesignData}</PACString><terminal instrumentType="FGEN" instrumentNumber="1"><vname download="true">Vin</vname><function type="WAVEFORM"><waveformType>SINE</waveformType><frequency>100.0</frequency><setupID>1</setupID><amplitude>1.5</amplitude><offset>2.0</offset><connInput>0</connInput></function></terminal><terminal instrumentType="SCOPE" instrumentNumber="2"><vname download="true">Vout</vname><function type="SAMPLING"><samplingRate>100000</samplingRate><samplingTime>0.01</samplingTime><connProbe_CHA>0</connProbe_CHA><coupling>1</coupling><triggerSource>0</triggerSource><connProbe_CHB>0</connProbe_CHB></function></terminal></experimentSpecification>',
'0',
'0')
select * from JobRecord;


