extern crate hyper;

use hyper::{Server, Response, Body};
use hyper::rt::Future;
use hyper::service::service_fn_ok;

fn main() {
    println!("Hello, Hyper!");
    let addr = ([0, 0, 0, 0], 8000).into();
    let builder = Server::bind(&addr);
    let server = builder
        .serve(|| {
            service_fn_ok(|_| {
                Response::new(Body::from("Almost microservice..."))
            })
        })
        .map_err(drop);
    hyper::rt::run(server);
}
