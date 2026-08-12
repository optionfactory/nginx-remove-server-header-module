# nginx-remove-server-header-module

A simple Nginx dynamic module that removes the `Server` header from HTTP responses.

## Usage

Load the compiled module at the very top of your `nginx.conf` file:

```nginx
load_module modules/opfa_http_remove_server_header_module.so;

events {
    # ...
}
```

Once loaded, it automatically strips the header from all HTTP traffic. No additional directives are required.
