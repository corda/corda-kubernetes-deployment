# CORDA PKI GENERATOR

With this tool you can generate certs for the Corda Node deployment using Corda Firewall.

Please either make sure that the tool (``generate_pki.sh``) can find the keytool executable in the path or then copy the required files into the bin folder.

The files required on Windows are: ``keytool.exe``, ``jli.dll``, ``msvcr100.dll``. 
These files can normally be found in your JDK installation, for example: ``C:\Program Files\Java\jre1.8.0_201\bin``

Tested on Linux, Mac OS and Windows.

## Configuration

The current configuration options can be found in the ``values.yaml`` file, see the section under ``corda.firewall``.
