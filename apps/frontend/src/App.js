import React, { useEffect, useState } from 'react';

function App() {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    // Fetch data from the backend API using the API URL defined in environment variables
    fetch(`${process.env.REACT_APP_API_URL}/api/data`)
      .then(response => response.json())
      .then(data => setData(data))
      .catch(error => setError(error));
  }, []);

  return (
    <div className="App">
      <h1>Frontend React App</h1>
      {error && <p>Error fetching data: {error.message}</p>}
      {data ? <pre>{JSON.stringify(data, null, 2)}</pre> : <p>Loading...</p>}
    </div>
  );
}

export default App;



// import logo from './logo.svg';
// import './App.css';

// function App() {
//   return (
//     <div className="App">
//       <header className="App-header">
//         <img src={logo} className="App-logo" alt="logo" />
//         <p>
//           Edit <code>src/App.js</code> and save to reload.
//         </p>
//         <a
//           className="App-link"
//           href="https://reactjs.org"
//           target="_blank"
//           rel="noopener noreferrer"
//         >
//           Learn React
//         </a>
//       </header>
//     </div>
//   );
// }

// export default App;


// import React, { useEffect, useState } from 'react';

// function App() {
//   const [data, setData] = useState(null);

//   useEffect(() => {
//     // Replace with your backend API URL when it's running
//     fetch('http://localhost:5000/api/data')
//       .then((response) => response.json())
//       .then((data) => setData(data))
//       .catch((error) => console.error('Error fetching data:', error));
//   }, []);

  // return (
//     <div className="App">
//       <h1>React Frontend</h1>
//       <p>Data from backend: {data ? data.message : 'Loading...'}</p>
//     </div>
//   );
// }

// export default App;
