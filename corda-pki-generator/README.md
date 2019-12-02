# CORDA PKI GENERATOR

With this tool you can generate certs for the Corda Node deployment using Corda Firewall.

Please either make sure that the tool (``generate_pki.sh``) can find the keytool executable in the path or then copy the required files into the bin folder (expected default).

The files required on Windows are: ``keytool.exe``, ``jli.dll``, ``msvcr100.dll``. These files can normally be found in your JDK installation, for example: ``C:\Program Files\Java\jre1.8.0_201\bin``

Not tested on Linux / Mac OS.

## Configuration

The current configuration options can be found in the ``generate_pki.sh`` file.

The options are as follows:

- ``CERTIFICATE_VALIDITY_DAYS``, defines how long the certificates should be valid for, in days, the default is 10 years (3650 days)
- ``BRIDGE_PASSWORD``, the password which will unlock the bridge certificate file, default password is ``bridgepass``
- ``FLOAT_PASSWORD``, the password which will unlock the float certificate file, default password is ``floatpass``
- ``TRUST_PASSWORD``, the password which will unlock the trust root certificate file, default password is ``trustpass``
- ``CA_PASSWORD``, the password which will unlock the certificate authority certificate file, default password is ``capass``

Fin.
