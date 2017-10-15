# Monome128

The monome grid can be a relatively tricky controller to get running - this README tries to answer some of the more common questions.  

## Port, IP and prefix

By default, Duplex is configured to use the following settings:

    IP Adress   127.0.0.1
    Input port  8002
    Output port 8082
    Prefix      /duplex

Duplex does not detect the monome automatically - you have to make sure that these settings are valid. Read about how to create a 'fixed-port' configuration below. 

## Using serialosc protocol

Serialosc is the standard method for communicating with monome devices, and the default option in Duplex. If you are not sure if serialosc protocol is enabled in Duplex, check whether Monome.lua contains the following statement: 

    self.comm_protocol = self.SERIALOSC



### Fixed-port configuration 

Duplex can't detect if serialosc is set to pick a random port number. 
Instead, you can create a configuration file for the monome, which will instruct serialosc to initialize your device with specific settings. 

The file is called m128-510.conf, and could look like this: 

    server {
     port = 8082
    }
    application {
     osc_prefix = "/duplex"
     host = "127.0.0.1"
     port = 8002
    }
    device {
     rotation = 0
    }


You can paste the above into a text file and save it, and then put the file into a path where serialosc will be able to read it. 

The exact location of this path depends on the operating system and version. 

**Windows 8**  
C:\Windows\SysWOW64\config\systemprofile\AppData\Local\Monome\serialosc\

**Windows XP**  
C:\Windows\system32\(null)\Monome\serialosc\

## MonomeSerial (old protocol)

The older alternative to serialosc is called MonomeSerial. Duplex supports this protocol too, and it is specified through the Monome.lua file. 

Look for the following statement and change it to this:

    self.comm_protocol = self.MONOMESERIAL

If MonomeSerial is running, make sure that port settings match those in Duplex and restart Renoise. 

