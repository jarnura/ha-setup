use cassandra_cpp::*;
use std::env;

#[tokio::main]
#[allow(clippy::result_large_err)]
async fn main() -> Result<()> {
    let mut cluster = Cluster::default();
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let username = env::var("USERNAME").expect("USERNAME must be set");
    let password = env::var("PASSWORD").expect("PASSWORD must be set");
    cluster.set_contact_points(&database_url).unwrap();
    cluster.set_credentials(&username, &password).unwrap();
    cluster.set_load_balance_round_robin();
    let session = cluster.connect().await?;

    let result = session
        .execute("SELECT keyspace_name FROM system_schema.keyspaces;")
        .await?;
    println!("{}", result);

    let mut iter = result.iter();
    while let Some(row) = iter.next() {
        let col: String = row.get_by_name("keyspace_name")?;
        println!("ks name = {}", col);
    }

    Ok(())
}
