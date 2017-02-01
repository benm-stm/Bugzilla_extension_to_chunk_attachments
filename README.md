# Bugzilla_extension_to_chunk_attachments
bugzilla extension that will permit to send webservice attachments in a chunked way there will be 2 parts in this repo :
- Server side (WSChunked): which is the bugzilla extension that contains all the methodes to chunk send and receive attachments.
- Client side (Client): which is a perl script to communicate with bugzilla's XMLRPC webservice and use the chunked way which we are using.
here is a small illustration of the interaction. (still in progress)

![alt tag](https://github.com/benm-stm/Bugzilla_extension_to_chunk_attachments/blob/master/chunked_illustration.png)

PS: Sorry i can't post the code of the synchronyzer it's not mine, but i'll post the code which i've wrote to communicate between a simple client for adding add  downloading attachments

