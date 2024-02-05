# Image uploader/browser with only Caddy

> Making an image uploader and browser server with the cleanest stack ever.

## Prelude

Recently a lot of people have been asking me about setting up a file server, mainly to serve their screenshots. As I have helped one of my friends set up his, I will put that into a clean guide in this blog post.

## Why Caddy?

When people asked me about methods to do this, they always get creative. Some thought an `rsync` + NGINX stack would be nice, others suggested a Node.JS application to go along. One even suggested me to use PHP applications with Apache.

So why Caddy? Caddy acts as a web server, similarly to NGINX. However, it has Let's Encrypt built in, no longer needing `certbot`. It has WebDAV as a clean extension, no longer needing any PHP/Node.JS application as an uploader. Finally, Caddy has a clean and small config syntax.

## Requirements

In this blog post (guide), I'll assume the target server runs on Ubuntu, which means it would use systemd for service management. Obviously, if the target server runs on NixOS, things would've been easier.

Some more obvious requirements would be an internet connection, a domain, and a static IP.

### Precaution

This guide assumes installation into the user home directory, not the system directory. If your server hosts multiple web applications on different users, this guide is *not* for you.

## 1\. Creating the folders needed

``` sh
mkdir ~/Pictures # The directory that pictures will go, our www root
```

## 2\. Getting Caddy

``` sh
# Since we need a Caddy with WebDAV for file uploads, we'll install Caddy with
# WebDAV. This script should put Caddy in /usr/bin.
curl https://getcaddy.com | bash -s personal http.webdav
```

## 3\. Setting up Caddy as a systemd service

This file goes to `/etc/systemd/system/caddy.service`. **Replace properties underneath "REPLACE ME"** for this to work.

``` ini
[Unit]
Description=Caddy HTTP/2 web server
Documentation=https://caddyserver.com/docs
After=network-online.target
Wants=network-online.target

[Service]
;REPLACE ME
User=$username
Group=$groupname
WorkingDirectory=/home/$username
ReadWriteDirectories=/home/$username
Environment=CADDYPATH=./.caddy

;Do not change these
ExecStart=/usr/local/bin/caddy -log stderr -agree=true -conf=./Caddyfile -root=./.caddy
ExecReload=/bin/kill -USR1 $MAINPID
Restart=on-failure
LimitNOFILE=1048576
```

### Reloading systemd services

``` sh
sudo systemctl daemon-reload
```

## 4\. Configure Caddy

For this section, we'll assume your domain is `example.com`. `i.example.com` would serve images, which would be CloudFlare protected. `d.example.com` would not be CloudFlare protected, as [CloudFlare breaks WebDAV](https://github.com/cloudflare/cloudflared/issues/69).

This file goes to `~/Caddyfile`. **Replace variables such as** `$username` for this to work. This username and password is only used for uploading.

``` 
i.example.com {
    root ./Pictures
    gzip
    browse
}

d.example.com {
    basicauth / $username $password
    webdav / {
       scope ./Pictures/
    }
}
```

## 5\. Start Caddy up

``` sh
sudo systemctl start caddy
```

## Testing Caddy

At this point, `i.example.com` should return you a webpage under HTTPS.

## Troubleshooting Caddy

To access Caddy logs, do `sudo journalctl -u caddy`.

## Uploading screenshots

### `curl` example - `$username` and `$password`

``` sh
curl --basic --user "$username:$password" -T $FILE_PATH https://d.example.com/
```

More advanced usages at https://code.blogs.iiidefix.net/posts/webdav-with-curl/

### ShareX - `<username>` and `<password>`

``` json
{
  "DestinationType": "ImageUploader, FileUploader",
  "RequestMethod": "PUT",
  "RequestURL": "https://d.example.com/$filename$",
  "Body": "Binary",
  "Headers": {
    "Authorization": "Basic $base64:<username>:<password>$"
  },
  "URL": "https://i.example.com/$filename$"
}
```
