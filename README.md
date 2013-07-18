This is a LabVIEW toolkit that replaces the experiment execution engine of the MIT ELVIS LabServer. 

It performs the following actions:

1. looks for queued experiments
2. If found dequeues the experiment
3. parses the experiment specification XML document
4. handles the parameters over to the specific LV VI 
5. executes the experiment
6. and writes the experiment result into the database to be retrieved by the Service Broker.
7. And so on..

It was designed for the MIT ELVIS Lab Server, but it should work work as a general solution for any batched lab.
