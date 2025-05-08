(() => {
  // Create badge element as soon as page loads
  function createBadge() {
    // Only create badge if we have a body element
    if (!document.body) {
      // Try again in 100ms if body isn't ready yet
      setTimeout(createBadge, 100);
      return;
    }
    
    // Create badge element
    const badge = document.createElement('div');
    
    // Set badge styles
    Object.assign(badge.style, {
      position: 'fixed',
      top: '0',
      left: '50%',
      transform: 'translateX(-50%)',
      backgroundColor: 'red',
      color: 'white',
      padding: '4px 12px',
      fontSize: '12px',
      fontWeight: 'bold',
      zIndex: '99999',
      textAlign: 'center',
      borderBottomLeftRadius: '4px',
      borderBottomRightRadius: '4px',
      boxShadow: '0 1px 3px rgba(0,0,0,0.3)',
      pointerEvents: 'none'
    });
    
    // Set badge text
    badge.textContent = 'DR';
    
    // Add badge to page
    document.body.appendChild(badge);
  }

  // Start immediately if possible
  if (document.readyState === 'loading') {
    window.addEventListener('DOMContentLoaded', createBadge);
  } else {
    createBadge();
  }
})(); 