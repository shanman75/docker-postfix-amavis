# The `mlan/postfix-amavis` repository

![travis-ci test](https://img.shields.io/travis/mlan/docker-postfix-amavis.svg?label=build&style=flat-square&logo=travis)
![docker build](https://img.shields.io/docker/cloud/build/mlan/postfix-amavis.svg?label=build&style=flat-square&logo=docker)
![image size](https://img.shields.io/docker/image-size/mlan/postfix-amavis/latest.svg?label=size&style=flat-square&logo=docker)
![docker stars](https://img.shields.io/docker/stars/mlan/postfix-amavis.svg?label=stars&style=flat-square&logo=docker)
![docker pulls](https://img.shields.io/docker/pulls/mlan/postfix-amavis.svg?label=pulls&style=flat-square&logo=docker)

This (non official) repository provides dockerized (MTA) [Mail Transfer Agent](https://en.wikipedia.org/wiki/Message_transfer_agent) (SMTP) service using [Postfix](http://www.postfix.org/) and [Dovecot](https://www.dovecot.org/) with [anti-spam](https://en.wikipedia.org/wiki/Anti-spam_techniques) and anti-virus filter using [amavisd-new](https://www.amavis.org/), [SpamAssassin](https://spamassassin.apache.org/) and [ClamAV](https://www.clamav.net/), which also provides sender authentication using [SPF](https://en.wikipedia.org/wiki/Sender_Policy_Framework) and [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail).

## Features

- MTA (SMTP) server and client [Postfix](http://www.postfix.org/)
- Anti-spam filter [amavisd-new](https://www.amavis.org/), [SpamAssassin](https://spamassassin.apache.org/) and [Razor](http://razor.sourceforge.net/)
- Anti-virus [ClamAV](https://www.clamav.net/)
- Sender authentication using [SPF](https://en.wikipedia.org/wiki/Sender_Policy_Framework) and [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail)
- SMTP client authentication on the SMTPS (port 465) and submission (port 587) using [Dovecot](https://www.dovecot.org/)
- Hooks for integrating [Let’s Encrypt](https://letsencrypt.org/) LTS certificates using the reverse proxy [Traefik](https://docs.traefik.io/)
- Consolidated configuration and run data under `/srv` to facilitate persistent storage
- Simplified configuration of mailbox table lookup using environment variables
- Simplified configuration of [LDAP](https://en.wikipedia.org/wiki/Lightweight_Directory_Access_Protocol) mailbox and alias lookup using environment variables
- Simplified configuration of [SMTP](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol) relay using environment variables
- Simplified configuration of [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail) keys using environment variables
- Simplified configuration of SMTP [TLS](https://en.wikipedia.org/wiki/Transport_Layer_Security) using environment variables
- Simplified generation of Diffie-Hellman parameters needed for [EDH](https://en.wikipedia.org/wiki/Diffie–Hellman_key_exchange) using utility script
- [Kopano-spamd](https://kb.kopano.io/display/WIKI/Kopano-spamd) integration with [mlan/kopano](https://github.com/mlan/docker-kopano)
- Multi-staged build providing the images `mini`, `base` and `full`
- Configuration using environment variables
- Log directed to docker daemon with configurable level
- Built in utility script `amavis-ls` which lists the contents of quarantine
- Built in utility script `run` helping configuring Postfix, AMaViS, SpamAssassin, Razor, ClamAV and Dovecot
- Makefile which can build images and do some management and testing
- Health check
- Small image size based on [Alpine Linux](https://alpinelinux.org/)
- Demo based on `docker-compose.yml` and `Makefile` files

## Tags

The MAJOR.MINOR.PATCH [SemVer](https://semver.org/) is
used. In addition to the three number version number you can use two or
one number versions numbers, which refers to the latest version of the 
sub series. The tag `latest` references the build based on the latest commit to the repository.

The `mlan/postfix-amavis` repository contains a multi staged built. You select which build using the appropriate tag from `mini`, `base` and `full`. The image `mini` only contain Postfix. The image built with the tag `base` extend `mini` to include [Dovecot](https://www.dovecot.org/), which provides mail delivery via IMAP and POP3 and SMTP client authentication as well as integration of [Let’s Encrypt](https://letsencrypt.org/) TLS certificates using [Traefik](https://docs.traefik.io/). The image with the tag `full`, which is the default, extend `base` with anti-spam and ant-virus [milters](https://en.wikipedia.org/wiki/Milter), and sender authentication via [SPF](https://en.wikipedia.org/wiki/Sender_Policy_Framework) and [DKIM](https://en.wikipedia.org/wiki/DomainKeys_Identified_Mail).

To exemplify the usage of the tags, lets assume that the latest version is `1.0.0`. In this case `latest`, `1.0.0`, `1.0`, `1`, `full`, `full-1.0.0`, `full-1.0` and `full-1` all identify the same image.

# Usage

Often you want to configure Postfix and its components. There are different methods available to achieve this. Many aspects can be configured using [environment variables](#environment-variables) described below. These environment variables can be explicitly given on the command line when creating the container. They can also be given in an `docker-compose.yml` file, see the [docker compose example](#docker-compose-example) below. Moreover docker volumes or host directories with desired configuration files can be mounted in the container. And finally you can `docker exec` into a running container and modify configuration files directly.

You can start a `mlan/postfix-amavis` container using the destination domain `example.com` and table mail boxes for info@example.com and abuse@example.com by issuing the shell command below.

```bash
docker run -d --name mta --hostname mx1.example.com -e MAIL_BOXES="info@example.com abuse@example.com" -p 127.0.0.1:25:25 mlan/postfix-amavis
```

One convenient way to test the image is to clone the [github](https://github.com/mlan/docker-postfix-amavis) repository and run the [demo](#demo) therein, see below.

## Docker compose example

An example of how to configure an web mail server using docker compose is given below. It defines 4 services, `app`, `mta`, `db` and `auth`, which are the web mail server, the mail transfer agent, the SQL database and LDAP authentication respectively.

```yaml
version: '3'

services:
  app:
    image: mlan/kopano
    networks:
      - backend
    ports:
      - "127.0.0.1:8008:80"    # WebApp & EAS (alt. HTTP)
      - "127.0.0.1:110:110"    # POP3 (not needed if all devices can use EAS)
      - "127.0.0.1:143:143"    # IMAP (not needed if all devices can use EAS)
      - "127.0.0.1:8080:8080"  # CalDAV (not needed if all devices can use EAS)
    depends_on:
      - auth
      - db
      - mta
    environment: # Virgin config, ignored on restarts unless FORCE_CONFIG given.
      - USER_PLUGIN=ldap
      - LDAP_URI=ldap://auth:389/
      - MYSQL_HOST=db
      - SMTP_SERVER=mta
      - LDAP_SEARCH_BASE=${LDAP_BASE-dc=example,dc=com}
      - LDAP_USER_TYPE_ATTRIBUTE_VALUE=${LDAP_USEROBJ-posixAccount}
      - LDAP_GROUP_TYPE_ATTRIBUTE_VALUE=${LDAP_GROUPOBJ-posixGroup}
      - MYSQL_DATABASE=${MYSQL_DATABASE-kopano}
      - MYSQL_USER=${MYSQL_USER-kopano}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD-secret}
      - POP3_LISTEN=*:110                       # also listen to eth0
      - IMAP_LISTEN=*:143                       # also listen to eth0
      - ICAL_LISTEN=*:8080                      # also listen to eth0
      - DISABLED_FEATURES=${DISABLED_FEATURES-} # also enable IMAP and POP3
      - SYSLOG_LEVEL=${SYSLOG_LEVEL-3}
    volumes:
      - app-conf:/etc/kopano
      - app-atch:/var/lib/kopano/attachments
      - app-sync:/var/lib/z-push
      - app-spam:/var/lib/kopano/spamd          # kopano-spamd integration
      - /etc/localtime:/etc/localtime:ro        # Use host timezone
    cap_add: # helps debugging by allowing strace
      - sys_ptrace

  mta:
    image: mlan/postfix-amavis
    hostname: ${MAIL_SRV-mx}.${MAIL_DOMAIN-example.com}
    networks:
      - backend
    ports:
      - "127.0.0.1:25:25"      # SMTP
    depends_on:
      - auth
    environment: # Virgin config, ignored on restarts unless FORCE_CONFIG given.
      - MESSAGE_SIZE_LIMIT=${MESSAGE_SIZE_LIMIT-25600000}
      - LDAP_HOST=auth
      - VIRTUAL_TRANSPORT=lmtp:app:2003
      - SMTP_RELAY_HOSTAUTH=${SMTP_RELAY_HOSTAUTH-}
      - SMTP_TLS_SECURITY_LEVEL=${SMTP_TLS_SECURITY_LEVEL-}
      - SMTP_TLS_WRAPPERMODE=${SMTP_TLS_WRAPPERMODE-no}
      - LDAP_USER_BASE=ou=${LDAP_USEROU-users},${LDAP_BASE-dc=example,dc=com}
      - LDAP_QUERY_FILTER_USER=(&(objectclass=${LDAP_USEROBJ-posixAccount})(mail=%s))
      - LDAP_QUERY_ATTRS_PASS=uid=user
      - DKIM_SELECTOR=${DKIM_SELECTOR-default}
      - SA_TAG_LEVEL_DEFLT=${SA_TAG_LEVEL_DEFLT-2.0}
      - SA_DEBUG=${SA_DEBUG-0}
      - SYSLOG_LEVEL=${SYSLOG_LEVEL-}
      - LOG_LEVEL=${LOG_LEVEL-0}
      - RAZOR_REGISTRATION=${RAZOR_REGISTRATION-}
    volumes:
      - mta:/srv
      - app-spam:/var/lib/kopano/spamd          # kopano-spamd integration
      - /etc/localtime:/etc/localtime:ro        # Use host timezone
    cap_add: # helps debugging by allowing strace
      - sys_ptrace

  db:
    image: mariadb
    command: ['--log_warnings=1']
    networks:
      - backend
    environment:
      - LANG=C.UTF-8
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD-secret}
      - MYSQL_DATABASE=${MYSQL_DATABASE-kopano}
      - MYSQL_USER=${MYSQL_USER-kopano}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD-secret}
    volumes:
      - db:/var/lib/mysql
      - /etc/localtime:/etc/localtime:ro        # Use host timezone

  auth:
    image: mlan/openldap
    networks:
      - backend
    environment:
      - LDAP_LOGLEVEL=parse
    volumes:
      - auth:/srv
      - /etc/localtime:/etc/localtime:ro        # Use host timezone

networks:
  backend:

volumes:
  app-atch:
  app-conf:
  app-spam:
  app-sync:
  auth:
  db:
  mta:
```

## Demo

This repository contains a [demo](demo) directory which hold the [docker-compose.yml](demo/docker-compose.yml) file as well as a [Makefile](demo/Makefile) which might come handy. Start with cloning the [github](https://github.com/mlan/docker-postfix-amavis) repository.

```bash
git clone https://github.com/mlan/docker-postfix-amavis.git
```

From within the [demo](demo) directory you can start the containers by typing:

```bash
make init
```

Then you can assess WebApp on the URL [`http://localhost:8008`](http://localhost:8008) and log in with the user name `demo` and password `demo` . 

```bash
make web
```

You can send yourself a test email by typing:

```bash
make test
```

When you are done testing you can destroy the test containers by typing

```bash
make destroy
```

## Persistent storage

By default, docker will store the configuration and run data within the container. This has the drawback that the configurations and queued and quarantined mail are lost together with the container should it be deleted. It can therefore be a good idea to use docker volumes and mount the run directories and/or the configuration directories there so that the data will survive a container deletion.

To facilitate such approach, to achieve persistent storage, the configuration and run directories of the services has been consolidated to `/srv/etc` and `/srv/var` respectively. So if you to have chosen to use both persistent configuration and run data you can run the container like this:

```
docker run -d --name mta -v mta:/srv -p 127.0.0.1:25:25 mlan/postfix-amavis
```

When you start a container which creates a new volume, as above, and the container has files or directories in the directory to be mounted (such as `/srv/` above), the directory’s contents are copied into the volume. The container then mounts and uses the volume, and other containers which use the volume also have access to the pre-populated content. More details [here](https://docs.docker.com/storage/volumes/#populate-a-volume-using-a-container).

## Configuration / seeding procedure

The `mlan/postfix-amavis` image contains an elaborate configuration / seeding procedure. The configuration is controlled by environment variables, described below.

The seeding procedure will leave any existing configuration untouched. This is achieved by the using an unlock file: `DOCKER_UNLOCK_FILE=/srv/etc/.docker.unlock`.
During the image build this file is created. When the the container is started the configuration / seeding procedure will be executed if the `DOCKER_UNLOCK_FILE` can be found. Once the procedure completes the unlock file is deleted preventing the configuration / seeding procedure to run when the container is restarted.

The unlock file approach was selected since it is difficult to accidentally _create_ a file.

In the rare event that want to modify the configuration of an existing container you can override the default behavior by setting `FORCE_CONFIG=OVERWRITE` to a no-empty string.

## Environment variables

When you create the `mlan/postfix-amavis` container, you can configure the services by passing one or more environment variables or arguments on the docker run command line. Once the services has been configured a lock file is created, to avoid repeating the configuration procedure when the container is restated.

To see all available postfix configuration variables you can run `postconf` within the container, for example like this:

```bash
docker exec -it mta postconf
```

If you do, you will notice that configuration variable names are all lower case, but they will be matched with all uppercase environment variables by the container initialization scripts.

## Outgoing SMTP relay

Sometimes you want outgoing email to be sent to a SMTP relay and _not_ directly to its destination. This could for instance be when your ISP is blocking port 25 or perhaps if you have a dynamic IP and are afraid of that mail servers will drop your outgoing emails because of that.

#### `SMTP_RELAY_HOSTAUTH`
This environment variable simplify a SMTP relay configuration. The SMTP relay host might require SASL authentication in which case user name and password can also be given in variable. The format is `"host:port user:passwd"`. Example: `SMTP_RELAY_HOSTAUTH="[example.relay.com]:587 e863ac2bc1e90d2b05a47b2e5c69895d:b35266f99c75d79d302b3adb42f3c75f"`

#### `SMTP_TLS_SECURITY_LEVEL`

You can enforce the use of TLS, so that the Postfix SMTP server announces STARTTLS and accepts no
mail without TLS encryption, by setting `SMTP_TLS_SECURITY_LEVEL=encrypt`. Default: `SMTP_TLS_SECURITY_LEVEL=none`.

#### `SMTP_TLS_WRAPPERMODE`

To configure the Postfix SMTP client connecting using the legacy SMTPS protocol instead of using the STARTTLS command, set `SMTP_TLS_WRAPPERMODE=yes`. This mode requires `SMTP_TLS_SECURITY_LEVEL=encrypt` or stronger. Default: `SMTP_TLS_WRAPPERMODE=no`

## Incoming SMTPS and submission client authentication

Postfix achieves client authentication using SASL provided by [Dovecot](https://dovecot.org/). Client authentication is the mechanism that is used on SMTP relay using SASL authentication, see the `SMTP_RELAY_HOSTAUTH`. Here the client authentication is arranged on the [smtps](https://en.wikipedia.org/wiki/SMTPS) port: 465 and [submission](https://en.wikipedia.org/wiki/Message_submission_agent) port: 587.

To avoid the risk of being an open relay the SMTPS and submission ([MSA](https://en.wikipedia.org/wiki/Message_submission_agent)) services are only activated when at least one SASL method has activated. Three methods are supported; LDAP, IMAP and password file. Any combination of methods can simultaneously be active. If more than one method is active, authentication is attempted in the following order; password file, LDAP and finally IMAP.

A method is activated when its required variables has been defined. For LDAP, `LDAP_QUERY_ATTRS_PASS` is needed in addition to the LDAP variables discussed in [LDAP mailbox lookup](#ldap-mailbox-lookup). IMAP needs the `SMTPD_SASL_IMAPHOST` variable and password file require `SMTPD_SASL_CLIENTAUTH`.

Additionally clients are required to authenticate using TLS to avoid password being sent in the clear. The configuration of the services are the similar with the exception that the SMTPS service uses the legacy SMTPS protocol; `SMTPD_TLS_WRAPPERMODE=yes`, whereas the submission service uses the STARTTLS protocol.

### Password file SASL client authentication `SMTPD_SASL_CLIENTAUTH`

You can list clients and their passwords in a space separated string using the format: `"username:{scheme}passwd"`. Example: `SMTPD_SASL_CLIENTAUTH="client1:{plain}passwd1 client2:{plain}passwd2"`. For security you might want to use encrypted passwords. One way to encrypt a password (`{plain}secret`) is by running

```bash
docker exec -it mta doveadm pw -p secret

{CRYPT}$2y$05$Osj5ebALV/bXo18H4BKLa.J8Izn23ilI8TNA/lIHz92TuQFbZ/egK
```

for use in `SMTPD_SASL_CLIENTAUTH`.

### LDAP SASL client authentication `LDAP_QUERY_ATTRS_PASS`

Using [LDAP with authentication binds](https://wiki.dovecot.org/AuthDatabase/LDAP/AuthBinds), Dovecot, binds, using the SMTPS client credentials, to the LDAP server which that verifies the them. See [LDAP](https://doc.dovecot.org/configuration_manual/authentication/ldap/) for more details.

The LDAP client configurations described in [LDAP mailbox lookup](#ldap-mailbox-lookup) are also used here. In addition to these, the binding `<user>` attribute needs to be specified using `LDAP_QUERY_ATTRS_PASS`. The `<user>` attribute is defined in this way `LDAP_QUERY_ATTRS_PASS=<user>=user`. To exemplify, if `uid` is the desired `<user>` attribute define `LDAP_QUERY_ATTRS_PASS=uid=user`.

#### `LDAP_QUERY_FILTER_PASS`

Dovecot sends a LDAP request defined by `LDAP_QUERY_FILTER_PASS` to lookup the DN that will be used for the authentication bind. Example: `LDAP_QUERY_FILTER_PASS=(&(objectclass=posixAccount)(uid=%u))`.

 `LDAP_QUERY_FILTER_PASS` can be omitted in which case the filter is being reconstructed from `LDAP_QUERY_FILTER_USER`. The reconstruction tries to replace the string `(mail=%s)` in `LDAP_QUERY_FILTER_USER` with `(<user>=%u),` where `<user>` is taken from `LDAP_QUERY_ATTRS_PASS`. Example: `LDAP_QUERY_FILTER_USER=(&(objectclass=posixAccount)(mail=%s))` and `LDAP_QUERY_ATTRS_PASS=uid=user` will result in this filter `(&(objectclass=posixAccount)(uid=%u))`.

### IMAP SASL client authentication `SMTPD_SASL_IMAPHOST`

Dovecot, can authenticate users against a remote IMAP server (RIMAP). For this to work it is sufficient to provide the address of the IMAP host, by using `SMTPD_SASL_IMAPHOST`. Examples `SMTPD_SASL_IMAPHOST=app`, `SASL_IMAP_HOST=192.168.1.123:143`.

For more details see [Authentication via remote IMAP server](https://doc.dovecot.org/configuration_manual/protocols/imap).

## Incoming destination domain

Postfix is configured to be
the final destination of the virtual/hosted domains defined by the environment variable `MAIL_DOMAIN`. If the domains are not properly configured Postfix will be rejecting the emails. When multiple domains are used the first domain in the list is considered to be the primary one.

#### `MAIL_DOMAIN`

The default value of `MAIL_DOMAIN=$(hostname -d)` is to
use the host name of the container minus the first component. So you can either use the environment variable `MAIL_DOMAIN` or the argument `--hostname`. So for example, `--hostname mx1.example.com` or `-e MAIL_DOMAIN="example.com secondary.com" `.

## Incoming TLS support

Transport Layer Security (TLS, formerly called SSL) provides certificate-based authentication and encrypted sessions. An encrypted session protects the information that is transmitted with SMTP mail or with SASL authentication.

Here TLS is activated for inbound messages when either `SMTPD_TLS_CHAIN_FILES` or `SMTPD_TLS_CERT_FILE` (or its [DSA](https://en.wikipedia.org/wiki/Digital_Signature_Algorithm) and [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm) counterparts) is not empty or `SMTPD_USE_TLS=yes`. The Postfix SMTP server generally needs a certificate and a private key to provide TLS. Both must be in [PEM](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail) format. The private key must not be encrypted, meaning: the key must be accessible without a password. The [RSA](https://en.wikipedia.org/wiki/RSA_(cryptosystem)) certificate and a private key files are identified by `SMTPD_TLS_CERT_FILE` and `SMTPD_TLS_KEY_FILE`.

#### `SMTPD_USE_TLS=yes`

If `SMTPD_USE_TLS=yes` is explicitly defined but there are no certificate files defined, a self-signed certificate will be generated when the container is created.

#### `SMTPD_TLS_CERT_FILE`

Specifies the [RSA](https://en.wikipedia.org/wiki/RSA_(cryptosystem)) [PEM](https://en.wikipedia.org/wiki/Privacy-Enhanced_Mail) certificate file within the container to be used with incoming TLS connections. The certificate file need to be made available in the container by some means. Example `SMTPD_TLS_CERT_FILE=cert.pem`. Additionally there are the [DSA](https://en.wikipedia.org/wiki/Digital_Signature_Algorithm), [ECDSA](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm) or chain counterparts; `SMTPD_TLS_DCERT_FILE`, `SMTPD_TLS_ECCERT_FILE` and `SMTPD_TLS_CHAIN_FILES`.

#### `SMTPD_TLS_KEY_FILE`

Specifies the RSA PEM private key file within the container to be used with incoming TLS connections. The private key file need to be made available in the container by some means. Example `SMTPD_TLS_KEY_FILE=key.pem`. Additionally there are the DSA, ECDSA or chain counterparts; `SMTPD_TLS_DKEY_FILE`, `SMTPD_TLS_ECKEY_FILE` and `SMTPD_TLS_CHAIN_FILES`.

### TLS forward secrecy

The term "Forward Secrecy" (or sometimes "Perfect Forward Secrecy") is used to describe security protocols in which the confidentiality of past traffic is not compromised when long-term keys used by either or both sides are later disclosed.

Forward secrecy is accomplished by negotiating session keys using per-session cryptographically-strong random numbers that are not saved, and signing the exchange with long-term authentication keys. Later disclosure of the long-term keys allows impersonation of the key holder from that point on, but not recovery of prior traffic, since with forward secrecy, the discarded random key agreement inputs are not available to the attacker.

The built in utility script `run` can be used to generate the Diffie-Hellman parameters needed for forward secrecy.

```bash
docker exec -it mta run update_postfix_dhparam
```

### Let’s Encrypt LTS certificates using Traefik

Let’s Encrypt provide free, automated, authorized certificates when you can demonstrate control over your domain. Automatic Certificate Management Environment (ACME) is the protocol used for such demonstration. There are many agents and applications that supports ACME, e.g., [certbot](https://certbot.eff.org/). The reverse proxy [Traefik](https://docs.traefik.io/) also supports ACME.

#### `ACME_FILE`, `ACME_POSTHOOK`

The `mlan/postfix-amavis` image looks for a file `ACME_FILE=/acme/acme.json` at container startup and every time this file changes certificates within this file are extracted. If the host or domain name of one of those certificates matches `HOSTNAME=$(hostname)` or `DOMAIN=${HOSTNAME#*.}` it will be used for TLS support.

Once the certificates and keys have been updated, we run the command in the environment variable `ACME_POSTHOOK="postfix reload"`. Postfix's parameters needs to be reloaded to update the LTS parameters. If such automatic reloading is not desired, set `ACME_POSTHOOK=` to empty.

So reusing certificates from Traefik will work out of the box if the `/acme` directory in the Traefik container is also mounted in the `mlan/postfix-amavis` container.

```bash
docker run -d -name mta -v proxy-acme:/acme:ro mlan/postfix-amavis
```

Note, if the target certificate Common Name (CN) or Subject Alternate Name (SAN) is changed the container needs to be restarted.

Moreover, do not set `SMTPD_TLS_CERT_FILE` and/or `SMTPD_TLS_KEY_FILE` when using `ACME_FILE`.

## Incoming anti-spam and anti-virus

[amavisd-new](https://www.amavis.org/) is a high-performance interface between mailer (MTA) and content checkers: virus scanners, and/or [SpamAssassin](https://spamassassin.apache.org/). Apache SpamAssassin is the #1 open source anti-spam platform giving system administrators a filter to classify email and block spam (unsolicited bulk email). It uses a robust scoring framework and plug-ins to integrate a wide range of advanced heuristic and statistical analysis tests on email headers and body text including text analysis, Bayesian filtering, DNS block-lists, and collaborative filtering databases. Clam AntiVirus is an anti-virus toolkit, designed especially for e-mail scanning on mail gateways.

[Vipul's Razor](http://razor.sourceforge.net/) is a distributed, collaborative, spam detection and filtering network. It uses a fuzzy [checksum](http://en.wikipedia.org/wiki/Checksum) technique to identify
message bodies based on signatures submitted by users, or inferred by
other techniques such as high-confidence Bayesian or DNSBL entries.

AMaViS will only insert mail headers in incoming messages with domain mentioned
in `MAIL_DOMAIN`. So proper configuration is needed for anti-spam and anti-virus to work.

#### `FINAL_VIRUS_DESTINY`, `FINAL_BANNED_DESTINY`, `FINAL_SPAM_DESTINY`, `FINAL_BAD_HEADER_DESTINY`

When an undesirable email is found, the action according to the `FINAL_*_DESTINY` variables will be taken. Possible settings for the `FINAL_*_DESTINY` variables are: `D_PASS`, `D_BOUNCE`,`D_REJECT` and `D_DISCARD`.

`D_PASS`: Mail will pass to recipients, regardless of bad contents. `D_BOUNCE`: Mail will not be delivered to its recipients, instead, a non-delivery notification (bounce) will be created and sent to the sender. `D_REJECT`: Mail will not be delivered to its recipients, instead, a reject response will be sent to the upstream MTA and that MTA may create a reject notice (bounce) and return it to the sender. `D_DISCARD`: Mail will not be delivered to its recipients and the sender normally will NOT be notified.

Default settings are: `FINAL_VIRUS_DESTINY=D_DISCARD`, `FINAL_BANNED_DESTINY=D_DISCARD`, `FINAL_SPAM_DESTINY=D_PASS`, `FINAL_BAD_HEADER_DESTINY=D_PASS`.

#### `SA_TAG_LEVEL_DEFLT`, `SA_TAG2_LEVEL_DEFLT`, `SA_KILL_LEVEL_DEFLT`

`SA_TAG_LEVEL_DEFLT=2.0` controls at which level (or above) spam info headers are added to mail. `SA_TAG2_LEVEL_DEFLT=6.2` controls at which level the 'spam detected' headers are added. `SA_KILL_LEVEL_DEFLT=6.9` set the trigger level when spam evasive actions are taken (e.g. blocking mail).

#### `RAZOR_REGISTRATION`

Razor, called by SpamAssassin, will check if the signature of the received email is registered in the Razor servers and adjust the spam score accordingly. [Razor](https://cwiki.apache.org/confluence/display/SPAMASSASSIN/RazorAmavisd) can also report detected spam to its servers, but then it needs to use a registered identity.

To register an identity with the Razor server, use `RAZOR_REGISTRATION`. You can request to be know as a certain user name, `RAZOR_REGISTRATION=username:passwd`. If you omit both user name and password, e.g., `RAZOR_REGISTRATION=:`, they will both be assigned to you by the Razor server. Likewise if password is omitted a password will be assigned by the Razor server. Razor users are encouraged
to use their email addresses as their user name. Example: `RAZOR_REGISTRATION=postmaster@example.com:secret`

### Managing the quarantine

A message is quarantined by being saved in the directory `/var/amavis/quarantine/` allowing manual inspection to determine weather or not to release it. The utility `amavis-ls` allow some simple inspection of what is in the quarantine. To do so type:

```bash
docker-compose exec mta amavis-ls
```

A quarantined message receives one additional header field: an
X-Envelope-To-Blocked. An X-Envelope-To still holds a complete list
of envelope recipients, but the X-Envelope-To-Blocked only lists its
subset (in the same order), where only those recipients are listed
which did not receive a message (e.g. being blocked by virus/spam/
banning... rules). This facilitates a release of a multi-recipient
message from a quarantine in case where some recipients had a message
delivered (e.g. spam lovers) and some had it blocked.

To release a quarantined message type:

```bash
docker-compose exec mta amavisd-release <file>
```

## Kopano-spamd integration with [mlan/kopano](https://github.com/mlan/docker-kopano)

[Kopano-spamd](https://kb.kopano.io/display/WIKI/Kopano-spamd) allow users to
drag messages into the Junk folder triggering the anti-spam filter to learn it
as spam. If the user moves the message back to the inbox, the anti-spam filter
will unlearn it.

To allow kopano-spamd integration the kopano and postfix-amavis containers need
to share the `KOPANO_SPAMD_LIB=/var/lib/kopano/spamd` folder.
If this directory exists within the
postfix-amavis container, the spamd-spam and spamd-ham service will be started.
They will run `sa-learn --spam` or `sa-learn --ham`,
respectively when a message is placed in either `var/lib/kopano/spamd/spam` or
`var/lib/kopano/spamd/ham`.

## Incoming SPF sender authentication

Sender Policy Framework (SPF) is an [email authentication](https://en.wikipedia.org/wiki/Email_authentication) method designed to detect forged sender addresses in emails. SPF allows the receiver to check that an email claiming to come from a specific domain comes from an IP address authorized by that domain's administrators. The list of authorized sending hosts and IP addresses for a domain is published in the [DNS](https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) records for that domain.

## DKIM sender authentication

Domain-Keys Identified Mail (DKIM) is an [email authentication](https://en.wikipedia.org/wiki/Email_authentication) method designed to detect forged sender addresses in emails. DKIM allows the receiver to check that an email claimed to have come from a specific [domain](https://en.wikipedia.org/wiki/Domain_name) was indeed authorized by the owner of that domain. It achieves this by affixing a [digital signature](https://en.wikipedia.org/wiki/Digital_signature), linked to a domain name, `MAIL_DOMAIN`, to each outgoing email message, which the receiver can verify by using the DKIM key published in the [DNS](https://en.wikipedia.org/wiki/Domain_Name_System_Security_Extensions) records for that domain.

amavisd-new is configured to check the digital signature of incoming email as well as add digital signatures to outgoing email.

#### `DKIM_KEYBITS`

The bit length used when creating new keys. Default: `DKIM_KEYBITS=2048`

#### `DKIM_SELECTOR`

The public key DNS record should appear as a TXT resource record at: `DKIM_SELECTOR._domainkey.MAIL_DOMAIN`. The TXT record to be used with the private key generated at container creation is written here: `/var/db/dkim/MAIL_DOMAIN.DKIM_SELECTOR._domainkey.txt`.
Default: `DKIM_SELECTOR=default`

#### `DKIM_PRIVATEKEY`

DKIM uses a private and public key pair used for signing and verifying email. A private key is created when the container is created. If you already have a private key you can pass it to the container by using the environment variable `DKIM_PRIVATEKEY`. For convenience the strings `-----BEGIN RSA PRIVATE KEY-----` and `-----END RSA PRIVATE KEY-----` can be omitted form the key string. For example `DKIM_PRIVATEKEY="MIIEpAIBAAKCAQEA04up8hoqzS...1+APIB0RhjXyObwHQnOzhAk"`

The private key is stored here `/var/db/dkim/MAIL_DOMAIN.DKIM_SELECTOR.privkey.pem`, so alternatively you can copy the private key into the container:

```bash
docker cp $MAIL_DOMAIN.$DKIM_SELECTOR.privkey.pem <container_name>:var/db/dkim
```

If you wish to create a new private key you can run:

```bash
docker exec -it <container_name> amavisd genrsa /var/db/dkim/$MAIL_DOMAIN.$DKIM_SELECTOR.privkey.pem $DKIM_KEYBITS
```

## Table mailbox lookup

Postfix can use a table as a source for any of its lookups including virtual mailbox and aliases. The `mlan/postfix-amavis` image provides a simple way to generate virtual mailbox lookup using the `MAIL_BOXES` environment variable.

#### `MAIL_BOXES`

Using the `MAIL_BOXES` environment variable you simply provide a space separated list with all email addresses that Postfix should accept incoming mail to. For example: `MAIL_BOXES="info@example.com abuse@example.com"`. The default value is empty.

#### `MAIL_ALIASES`

Using the `MAIL_ALIASES` environment variable you simply provide a space separated list with email alias addresses that Postfix should accept incoming mail to, using the following syntax: `MAIL_ALIASES="alias1:target1a,target1b alias2:target2"`. For example: `MAIL_ALIASES="root:info,info@example.com postmaster:root"`. The default value is empty.

## LDAP mailbox lookup

Postfix can use an LDAP directory as a source for any of its lookups including virtual mailbox and aliases.

For LDAP mailbox lookup to work `LDAP_HOST`, `LDAP_USER_BASE` and `LDAP_QUERY_FILTER_USER` need to be configured. LDAP can also be used for alias lookup, in which case use `LDAP_QUERY_FILTER_ALIAS`. In addition LDAP can be used to lookup mail groups using `LDAP_QUERY_FILTER_GROUP` and `LDAP_QUERY_FILTER_EXPAND`. For detailed explanation see [ldap_table](http://www.postfix.org/ldap_table.5.html).

If the LDAP server is not configured to allow anonymous queries, you use `LDAP_BIND_DN` and `LDAP_BIND_PW` to proved LDAP user and password to be used for the queries.

### Required LDAP parameters

#### `LDAP_HOST`

Use `LDAP_HOST` to configure the connection to the LDAP server. When the default port (389) is used just providing the server name is often sufficient. You can also use full URL or part thereof, for example: `LDAP_HOST=auth`, `LDAP_HOST=auth:389`, `LDAP_HOST=ldap://ldap.example.com:1444`.

#### `LDAP_USER_BASE`

The `LDAP_USER_BASE`, is the base DNs at which to conduct the searches for users. Example: `LDAP_USER_BASE=ou=people,dc=example,dc=com`.

#### `LDAP_QUERY_FILTER_USER`

This is the filter used to search the directory, where `%s` is a
substitute for the address Postfix is trying to resolve. Example, only consider the email address of users who also have `objectclass=posixAccount`; `LDAP_QUERY_FILTER_USER=(&(objectclass=posixAccount)(mail=%s))`.

### Optional LDAP parameters

#### `LDAP_GROUP_BASE`

The `LDAP_GROUP_BASE` is the base DNs at which to conduct the searches for groups. Example: `LDAP_GROUP_BASE=ou=groups,dc=example,dc=com`.

#### `LDAP_QUERY_FILTER_ALIAS`

This is the filter used to search the directory, where `%s` is a
substitute for the address Postfix is trying to resolve. Example, only consider email aliases of users who also have `objectclass=posixAccount`; `LDAP_QUERY_FILTER_ALIAS=(&(objectclass=posixAccount)(aliases=%s))`.

#### `LDAP_QUERY_FILTER_GROUP`, `LDAP_QUERY_FILTER_EXPAND`

To deliver mails to a member of a group the email addresses of the individual must be resolved. For resolving group members use `LDAP_QUERY_FILTER_GROUP` and to expand group members’ mail into `uid` use `LDAP_QUERY_FILTER_EXPAND`.

Example, only consider group mail from group who is of `objectclass=group`: `LDAP_QUERY_FILTER_GROUP=(&(objectclass=group)(mail=%s))` and then only consider user with matching `uid` who is of `objectclass=posixAccount`; `LDAP_QUERY_FILTER_EXPAND=(&(objectclass=posixAccount)(uid=%s))`.

#### `LDAP_BIND_DN`, `LDAP_BIND_PW`

The defaults for these environment variables are empty. If you do have to bind, do it with this distinguished name and password. Example: `LDAP_BIND_DN=uid=admin,dc=example,dc=com`, `LDAP_BIND_PW=secret`.


## Delivery transport
The `mlan/postfix-amavis` image is designed primarily to work with a companion software which holds the mail boxes. That is, Postfix is not intended to be used for final delivery.

#### `VIRTUAL_TRANSPORT`

Postfix delivers the messages to the companion software, like [Kolab](https://hub.docker.com/r/kvaps/kolab), [Kopano](https://cloud.docker.com/u/mlan/repository/docker/mlan/kopano) or [Zimbra](https://hub.docker.com/r/jorgedlcruz/zimbra/), using a transport mechanism you specify using the environment variable `VIRTUAL_TRANSPORT`. [LMTP](https://en.wikipedia.org/wiki/Local_Mail_Transfer_Protocol) is one such transport mechanism. One example of final delivery transport to Kopano is: `VIRTUAL_TRANSPORT=lmtp:app:2003`

Local mail boxes will be created if there is no `VIRTUAL_TRANSPORT` defined. The local mail boxes will be created in the directory `/var/mail`. For example `/var/mail/info@example.com`.

## Message size limit `MESSAGE_SIZE_LIMIT`

The maximal size in bytes of a message, including envelope information. Default: `MESSAGE_SIZE_LIMIT=10240000` ~10MB. Many mail servers are configured with maximal size of 10MB, 20MB or 25MB.

## Logging `SYSLOG_LEVEL`, `LOG_LEVEL`, `SA_DEBUG`

The level of output for logging is in the range from 0 to 7. The default is: `SYSLOG_LEVEL=5`

| emerg | alert | crit | err  | warning | notice | info | debug |
| ----- | ----- | ---- | ---- | ------- | ------ | ---- | ----- |
| 0     | 1     | 2    | 3    | 4       | **5**  | 6    | 7     |

Separately, `LOG_LEVEL` and `SA_DEBUG` control the logging level of amavisd-new and spamassasin respectively.
`LOG_LEVEL` takes valued from 0 to 5 and `SA_DEBUG` is either 1 (activated) or 0 (deactivated). Note that these messages will only appear in the log if `SYSLOG_LEVEL` is 7 (debug).

# Knowledge base

Here some topics relevant for arranging a mail server are presented.

## DNS records

The [Domain Name System](https://en.wikipedia.org/wiki/Domain_Name_System) (DNS) is a [hierarchical](https://en.wikipedia.org/wiki/Hierarchical) and [decentralized](https://en.wikipedia.org/wiki/Decentralised_system) naming system for computers, services, or other resources connected to the [Internet](https://en.wikipedia.org/wiki/Internet) or a private network.

### MX record

A mail exchanger record (MX record) specifies the [mail server](https://en.wikipedia.org/wiki/Mail_server) responsible for accepting [email](https://en.wikipedia.org/wiki/Email) messages on behalf of a domain name. It is a [resource record](https://en.wikipedia.org/wiki/Resource_record) in the DNS. The MX record should correspond to the host name of the image.

### SPF record

An [SPF record](https://en.wikipedia.org/wiki/Sender_Policy_Framework) is a [TXT](https://en.wikipedia.org/wiki/TXT_Record) record that is part of a domain's DNS zone file.
The TXT record specifies a list of authorized host names/IP addresses that mail can originate from for a given domain name. An example of such TXT record is give below

```
"v=spf1 ip4:192.0.2.0/24 mx include:example.com a -all"
```

### DKIM record

The public key DNS record should appear as a [TXT](https://en.wikipedia.org/wiki/TXT_Record) resource record at: `DKIM_SELECTOR._domainkey.DOMAIN`

The data returned from the query of this record is also a list of tag-value pairs. It includes the domain's [public key](https://en.wikipedia.org/wiki/Public_key), along with other key usage tokens and flags as in this example:

```
"k=rsa; t=s; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDmzRmJRQxLEuyYiyMg4suA2Sy
MwR5MGHpP9diNT1hRiwUd/mZp1ro7kIDTKS8ttkI6z6eTRW9e9dDOxzSxNuXmume60Cjbu08gOyhPG3
GfWdg7QkdN6kR4V75MFlw624VY35DaXBvnlTJTgRg/EW72O1DiYVThkyCgpSYS8nmEQIDAQAB"
```

The receiver can use the public key (value of the p tag) to then decrypt the hash value in the header field, and at the same time recalculate the hash value for the mail message (headers and body) that was received.

## ClamAV, virus signatures and memory usage

ClamAV holds search strings and regular expression in memory. The algorithms used are from the 1970s and are very memory efficient. The problem is the huge number of virus signatures. This leads to the algorithms' data-structures growing quite large. Consequently, The minimum recommended system requirements are for using [ClamAV](https://www.clamav.net/documents/introduction) is 1GiB.

# Implementation

Here some implementation details are presented.

## Container init scheme

The container use [runit](http://smarden.org/runit/), providing an init scheme and service supervision, allowing multiple services to be started. There is a Gentoo Linux [runit wiki](https://wiki.gentoo.org/wiki/Runit).

When the container is started, execution is handed over to the script [`docker-entrypoint.sh`](src/docker/bin/docker-entrypoint.sh). It has 4 stages; 0) *register* the SIGTERM [signal (IPC)](https://en.wikipedia.org/wiki/Signal_(IPC)) handler, which is programmed to run all exit scripts in `/etc/docker/exit.d/` and terminate all services, 1) *run* all entry scripts in `/etc/docker/entry.d/`, 2) *start* services registered in `SVDIR=/etc/service/`, 3) *wait* forever, allowing the signal handler to catch the SIGTERM and run the exit scripts and terminate all services.

The entry scripts are responsible for tasks like, seeding configurations, register services and reading state files. These scripts are run before the services are started.

There is also exit script that take care of tasks like, writing state files. These scripts are run when docker sends the SIGTERM signal to the main process in the container. Both `docker stop` and `docker kill --signal=TERM` sends SIGTERM.

## Build assembly

The entry and exit scripts, discussed above, as well as other utility scrips are copied to the image during the build phase. The source file tree was designed to facilitate simple scanning, using wild-card matching, of source-module directories for files that should be copied to image. Directory names indicate its file types so they can be copied to the correct locations. The code snippet in the `Dockerfile` which achieves this is show below.

```dockerfile
COPY	src/*/bin $DOCKER_BIN_DIR/
COPY	src/*/entry.d $DOCKER_ENTRY_DIR/
```

There is also a mechanism for excluding files from being copied to the image from some source-module directories. Source-module directories to be excluded are listed in the file [`.dockerignore`](https://docs.docker.com/engine/reference/builder/#dockerignore-file). Since we don't want files from the module `notused` we list it in the `.dockerignore` file:

```sh
src/notused
```
