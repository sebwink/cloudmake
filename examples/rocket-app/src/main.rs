#![feature(proc_macro_hygiene, decl_macro)]

#[macro_use] extern crate rocket;
extern crate rocket_contrib;
#[macro_use] extern crate serde_derive;

use rocket::request::Form;
use rocket_contrib::serve::StaticFiles;
use rocket_contrib::json::Json;

#[derive(FromForm)]
struct GcdInput {
    n: u64,
    m: u64,
}

#[derive(Serialize)]
struct GcdResponse {
    gcd: u64,
}

#[post("/", data = "<data>")]
fn post_gcd(data: Form<GcdInput>) -> Json<GcdResponse> {
    Json(GcdResponse {
        gcd: gcd(data.n, data.m),
    })
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

fn main() {
    rocket::ignite()
        .mount("/", StaticFiles::from("static"))
        .mount("/gcd", routes![post_gcd])
        .launch();
}
