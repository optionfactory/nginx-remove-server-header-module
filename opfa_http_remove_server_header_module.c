#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>

static ngx_http_output_header_filter_pt  ngx_http_next_header_filter;

static ngx_int_t opfa_http_remove_server_header_install_handler(ngx_conf_t *cf);
static ngx_int_t opfa_http_remove_server_header_handler(ngx_http_request_t *r);

static ngx_command_t opfa_http_remove_server_header_commands[] = {
    ngx_null_command /* command termination */
};

/* The module context. */
static ngx_http_module_t opfa_http_remove_server_header_module_ctx = {
    NULL, /* preconfiguration */
    opfa_http_remove_server_header_install_handler, /* postconfiguration */

    NULL, /* create main configuration */
    NULL, /* init main configuration */

    NULL, /* create server configuration */
    NULL, /* merge server configuration */

    NULL, /* create location configuration */
    NULL /* merge location configuration */
};

/* Module definition. */
ngx_module_t opfa_http_remove_server_header_module = {
    NGX_MODULE_V1,
    &opfa_http_remove_server_header_module_ctx, /* module context */
    opfa_http_remove_server_header_commands, /* module directives */
    NGX_HTTP_MODULE, /* module type */
    NULL, /* init master */
    NULL, /* init module */
    NULL, /* init process */
    NULL, /* init thread */
    NULL, /* exit thread */
    NULL, /* exit process */
    NULL, /* exit master */
    NGX_MODULE_V1_PADDING
};


static ngx_int_t opfa_http_remove_server_header_handler(ngx_http_request_t *r)
{
    ngx_table_elt_t *h = r->headers_out.server;
    if (h == NULL) {
        h = ngx_list_push(&r->headers_out.headers);
        if (h == NULL) {
            return NGX_ERROR;
        }
        ngx_str_set(&h->key, "Server");
        ngx_str_set(&h->value, "");
        r->headers_out.server = h;
    }
    h->hash = 0;
    return ngx_http_next_header_filter(r);
}



static ngx_int_t opfa_http_remove_server_header_install_handler(ngx_conf_t *cf)
{
    ngx_http_next_header_filter = ngx_http_top_header_filter;
    ngx_http_top_header_filter = opfa_http_remove_server_header_handler;
    return NGX_OK;
}