module.exports = {
  networks: {
    development: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 7545,        // Standard Ganache port
      network_id: "*",   // Match any network id
    },
  },

  contracts_directory: "./contracts",
  compilers: {
    solc: {
      version:"0.8.19",
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },

  db: {
    enabled: false,
  },
};
