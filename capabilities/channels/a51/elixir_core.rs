// Elixir-style functional utilities rewritten in Rust
// Part of the G.U.N.D.A.M. Cosmic Pipeline Core

pub struct Enum;

impl Enum {
    pub fn map<T, U, F>(vec: Vec<T>, f: F) -> Vec<U>
    where
        F: Fn(T) -> U,
    {
        vec.into_iter().map(f).collect()
    }

    pub fn filter<T, F>(vec: Vec<T>, f: F) -> Vec<T>
    where
        F: Fn(&T) -> bool,
    {
        vec.into_iter().filter(f).collect()
    }

    pub fn reduce<T, U, F>(vec: Vec<T>, acc: U, f: F) -> U
    where
        F: Fn(U, T) -> U,
    {
        vec.into_iter().fold(acc, f)
    }
}

pub struct Stream;

impl Stream {
    pub fn cycle<T: Clone>(vec: Vec<T>) -> impl Iterator<Item = T> {
        vec.into_iter().cycle()
    }
}

// GenServer-like Actor Model in Rust
pub trait GenServer {
    type State;
    type Message;
    type Response;

    fn init(args: Vec<String>) -> Self::State;
    fn handle_call(msg: Self::Message, state: &mut Self::State) -> Self::Response;
    fn handle_cast(msg: Self::Message, state: &mut Self::State);
}

pub struct CosmicAgent;

impl GenServer for CosmicAgent {
    type State = i32;
    type Message = String;
    type Response = String;

    fn init(_args: Vec<String>) -> Self::State {
        0
    }

    fn handle_call(msg: Self::Message, state: &mut Self::State) -> Self::Response {
        *state += 1;
        format!("Processed: {} (State: {})", msg, state)
    }

    fn handle_cast(msg: Self::Message, state: &mut Self::State) {
        println!("Cast received: {}", msg);
        *state -= 1;
    }
}
