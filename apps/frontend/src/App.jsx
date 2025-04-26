import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Load API URL from environment or config
const API_URL = import.meta.env.VITE_API_URL || 'https://api.example.com';

function App() {
  const [apiInfo, setApiInfo] = useState(null);
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [newItem, setNewItem] = useState({ name: '', description: '' });

  // Fetch API info on component mount
  useEffect(() => {
    const fetchApiInfo = async () => {
      try {
        const response = await axios.get(`${API_URL}/api/v1/info`);
        setApiInfo(response.data);
      } catch (err) {
        console.error('Error fetching API info:', err);
        setError('Failed to connect to API. Please try again later.');
      }
    };

    fetchApiInfo();
  }, []);

  // Fetch items on component mount
  useEffect(() => {
    const fetchItems = async () => {
      try {
        setLoading(true);
        const response = await axios.get(`${API_URL}/api/v1/items`);
        setItems(response.data);
        setError(null);
      } catch (err) {
        console.error('Error fetching items:', err);
        setError('Failed to load items. Please try again later.');
      } finally {
        setLoading(false);
      }
    };

    fetchItems();
  }, []);

  // Handle input changes
  const handleInputChange = (e) => {
    const { name, value } = e.target;
    setNewItem({ ...newItem, [name]: value });
  };

  // Handle form submission
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!newItem.name) {
      setError('Name is required');
      return;
    }
    
    try {
      setLoading(true);
      const response = await axios.post(`${API_URL}/api/v1/items`, newItem);
      setItems([...items, response.data]);
      setNewItem({ name: '', description: '' });
      setError(null);
    } catch (err) {
      console.error('Error creating item:', err);
      setError('Failed to create item. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app">
      <header>
        <h1>Cloud Native Demo App</h1>
        {apiInfo && (
          <div className="api-info">
            <p>Connected to: {apiInfo.name} v{apiInfo.version}</p>
            <p>Environment: {apiInfo.environment}</p>
            <p>Server Time: {new Date(apiInfo.timestamp).toLocaleString()}</p>
          </div>
        )}
      </header>

      <main>
        <section className="form-section">
          <h2>Add New Item</h2>
          {error && <div className="error">{error}</div>}
          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label htmlFor="name">Name:</label>
              <input
                type="text"
                id="name"
                name="name"
                value={newItem.name}
                onChange={handleInputChange}
                required
              />
            </div>
            <div className="form-group">
              <label htmlFor="description">Description:</label>
              <textarea
                id="description"
                name="description"
                value={newItem.description}
                onChange={handleInputChange}
              />
            </div>
            <button type="submit" disabled={loading}>
              Add Item
            </button>
          </form>
        </section>

        <section className="items-section">
          <h2>Items</h2>
          {loading && <p>Loading...</p>}
          {!loading && items.length === 0 && <p>No items found.</p>}
          {!loading && items.length > 0 && (
            <ul className="items-list">
              {items.map((item) => (
                <li key={item.id} className="item-card">
                  <h3>{item.name}</h3>
                  <p>{item.description || 'No description provided.'}</p>
                  {item.createdAt && (
                    <small>Created: {new Date(item.createdAt).toLocaleString()}</small>
                  )}
                </li>
              ))}
            </ul>
          )}
        </section>
      </main>

      <footer>
        <p>&copy; {new Date().getFullYear()} Cloud Native Demo</p>
      </footer>
    </div>
  );
}

export default App;