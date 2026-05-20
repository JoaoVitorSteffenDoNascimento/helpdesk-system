import { NavLink } from 'react-router-dom';

function Navbar() {
  return (
    <header className="navbar">
      <NavLink to="/" className="brand" aria-label="Help Desk home">
        <span className="brand-mark">HD</span>
        <span>Help Desk</span>
      </NavLink>
      <nav className="nav-links" aria-label="Main navigation">
        <NavLink to="/">Home</NavLink>
        <NavLink to="/tickets">Tickets</NavLink>
        <NavLink to="/users">Users</NavLink>
      </nav>
    </header>
  );
}

export default Navbar;
