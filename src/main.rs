use cassandra_cpp::*;
use std::env;

#[tokio::main]
#[allow(clippy::result_large_err)]
async fn main() -> Result<()> {
    // Connect to the Cassandra database using environment variables for credentials
    let mut cluster = Cluster::default();
    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let username = env::var("USERNAME").expect("USERNAME must be set");
    let password = env::var("PASSWORD").expect("PASSWORD must be set");

    // Set the contact points (hostnames or IP addresses) for the Cassandra cluster
    cluster.set_contact_points(&database_url).unwrap();

    // Set the username and password for authentication with the Cassandra cluster
    cluster.set_credentials(&username, &password).unwrap();

    // Configure the load balancing strategy to use round-robin (default)
    cluster.set_load_balance_round_robin();

    // Create a new session object to interact with the Cassandra database
    let session = cluster.connect().await?;

    // Execute a CQL query to retrieve all keyspace names from the system_schema.keyspaces table
    let result = session
        .execute("SELECT keyspace_name FROM system_schema.keyspaces;")
        .await?;

    // Print the result of the query
    println!("{}", result);

    // Iterate over each row in the result set and print the value of the "keyspace_name" column
    let mut iter = result.iter();
    while let Some(row) = iter.next() {
        let col: String = row.get_by_name("keyspace_name")?;
        println!("ks name = {}", col);
    }

    // Return a successful result indicating that the program has completed successfully
    Ok(())
}
