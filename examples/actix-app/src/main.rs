#[macro_use] extern crate serde_derive;
extern crate actix_web;

use actix_web::{
    server,
    App,
    Json,
    Form,
    Result,
    HttpRequest,
    HttpResponse,
    http::Method,
};

#[derive(Deserialize)]
struct GcdInput {
    n: u64,
    m: u64,
}

#[derive(Serialize)]
struct GcdResponse {
    gcd: u64,
}

fn gcd(mut n: u64, mut m: u64) -> u64 {
    assert!(n != 0 && m != 0);
    while m != 0 {
        if m < n {
            let t = m;
            m = n;
            n = t;
        }
        m = m % n;
    }
    return n;
}

fn post_gcd(data: Form<GcdInput>) -> Result<Json<GcdResponse>> {
    Ok(Json(GcdResponse {
        gcd: gcd(data.n, data.m),
    }))
}

fn index(_req: &HttpRequest) -> HttpResponse {
    HttpResponse::Ok()
        .content_type("text/html")
        .body(r#"
            <!DOCTYPE html>
            <html>
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width">
                    <title>GCD Calculator!</title>
                </head>
                <body>
                    <form action="/gcd" method="post">
                        <input type="text" name="n"/>
                        <input type="text" name="m"/>
                        <button type="submit">Compute GCD</button>
                    </form>
                </body>
            </html>
        "#)
}

fn main() {
    let app = || App::new()
        .resource("/", |r| r.f(index))
        .resource("/gcd", |r| r.method(Method::POST).with(post_gcd));
    server::new(app)
        .bind("0.0.0.0:8088")
        .unwrap()
        .run();
}
