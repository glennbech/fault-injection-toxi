import React, { useState } from 'react'
import { motion } from 'framer-motion'
import { SERVICE_URL } from '../config.js'

const Cart = ({ cart, onClose, onUpdateQuantity, onRemoveItem, totalPrice }) => {
  const [isProcessing, setIsProcessing] = useState(false)
  const [statusMessage, setStatusMessage] = useState(null)

  const handleCheckout = async () => {
    if (cart.length === 0) {
      setStatusMessage({ type: 'error', text: 'Your cart is empty' })
      return
    }

    setIsProcessing(true)
    setStatusMessage({ type: 'loading', text: 'Processing your order...' })

    try {
      const order = {
        items: cart.map(item => ({
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity
        })),
        total: totalPrice,
        timestamp: new Date().toISOString()
      }

      console.log('Sending order to service:', order)

      // Create AbortController for 5-second timeout (enterprise architecture rule)
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 5000)

      const response = await fetch(SERVICE_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(order),
        signal: controller.signal
      })

      clearTimeout(timeoutId)

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      const result = await response.json()
      console.log('Order response:', result)

      setStatusMessage({ type: 'success', text: 'Order placed successfully!' })

      // Clear cart after successful order
      setTimeout(() => {
        cart.forEach(item => onRemoveItem(item.id))
        setStatusMessage(null)
        onClose()
      }, 2000)

    } catch (error) {
      console.error('Checkout failed:', error)

      // Check if it was a timeout
      if (error.name === 'AbortError') {
        setStatusMessage({
          type: 'error',
          text: 'Order timed out after 5 seconds (enterprise timeout policy)'
        })
      } else {
        setStatusMessage({
          type: 'error',
          text: `Order failed: ${error.message}`
        })
      }
    } finally {
      setIsProcessing(false)
    }
  }

  return (
    <>
      <motion.div
        className="cart-backdrop"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        onClick={onClose}
      />

      <motion.div
        className="cart-panel"
        initial={{ x: '100%' }}
        animate={{ x: 0 }}
        exit={{ x: '100%' }}
        transition={{ type: 'spring', damping: 25, stiffness: 200 }}
      >
        <div className="cart-header">
          <h2>Your Cart</h2>
          <motion.button
            className="close-button"
            onClick={onClose}
            whileHover={{ scale: 1.1, rotate: 90 }}
            whileTap={{ scale: 0.9 }}
          >
            ×
          </motion.button>
        </div>

        <div className="cart-items">
          {cart.length === 0 ? (
            <p className="empty-cart">Your cart is empty</p>
          ) : (
            cart.map(item => (
              <motion.div
                key={item.id}
                className="cart-item"
                layout
                initial={{ opacity: 0, x: 20 }}
                animate={{ opacity: 1, x: 0 }}
                exit={{ opacity: 0, x: -20 }}
              >
                <div className="cart-item-image">{item.image}</div>
                <div className="cart-item-details">
                  <h4>{item.name}</h4>
                  <p className="item-price">${item.price.toFixed(2)}</p>

                  <div className="quantity-controls">
                    <motion.button
                      whileTap={{ scale: 0.9 }}
                      onClick={() => onUpdateQuantity(item.id, item.quantity - 1)}
                    >
                      −
                    </motion.button>
                    <span>{item.quantity}</span>
                    <motion.button
                      whileTap={{ scale: 0.9 }}
                      onClick={() => onUpdateQuantity(item.id, item.quantity + 1)}
                    >
                      +
                    </motion.button>
                    <motion.button
                      className="remove-button"
                      onClick={() => onRemoveItem(item.id)}
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      Remove
                    </motion.button>
                  </div>
                </div>
              </motion.div>
            ))
          )}
        </div>

        <div className="cart-footer">
          <div className="cart-total">
            <span>Total:</span>
            <span className="total-amount">${(totalPrice || 0).toFixed(2)}</span>
          </div>

          <motion.button
            className="checkout-button"
            onClick={handleCheckout}
            disabled={isProcessing || cart.length === 0}
            whileHover={{ scale: cart.length > 0 && !isProcessing ? 1.05 : 1 }}
            whileTap={{ scale: cart.length > 0 && !isProcessing ? 0.95 : 1 }}
          >
            {isProcessing ? 'Processing...' : 'Checkout'}
          </motion.button>

          {statusMessage && (
            <motion.div
              className={`status-message ${statusMessage.type}`}
              initial={{ opacity: 0, y: -10 }}
              animate={{ opacity: 1, y: 0 }}
            >
              {statusMessage.text}
            </motion.div>
          )}
        </div>
      </motion.div>
    </>
  )
}

export default Cart
