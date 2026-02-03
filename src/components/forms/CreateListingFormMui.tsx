'use client';

import { useState } from 'react';
import {
  Box,
  Grid as MuiGrid,
  Button,
  ButtonProps,
  TextField,
  Select,
  MenuItem,
  Typography,
  FormControl,
  InputLabel,
  InputAdornment,
} from '@mui/material';
import { styled } from '@mui/material/styles';

interface TradeTypeButtonProps extends ButtonProps {
  selected: boolean;
}

const TradeTypeButton = styled(Button)<TradeTypeButtonProps>(({ theme, selected }) => ({
  height: '8rem',
  border: `2px solid ${selected ? theme.palette.primary.main : theme.palette.grey[400]}`,
  backgroundColor: selected ? '#e3f2fd' : 'transparent',
  transition: 'all 0.3s',
  '&:hover': {
    borderColor: theme.palette.primary.light,
  },
}));

export default function CreateListingFormMui() {
  const [tradeType, setTradeType] = useState<'barter' | 'cash' | 'mixed'>('mixed');
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [cashPrice, setCashPrice] = useState('');
  const [exchange, setExchange] = useState('');
  const [category, setCategory] = useState('');
  const [imageUrl, setImageUrl] = useState('');

  const handleSubmit = async (event: React.FormEvent) => {
    event.preventDefault();
    const formData = {
      tradeType,
      title,
      description,
      cashPrice: tradeType !== 'barter' ? parseFloat(cashPrice) : null,
      exchange: tradeType !== 'cash' ? exchange : null,
      category,
      imageUrl,
    };
    console.log('Submitting Form Data:', formData);

    try {
      const response = await fetch('http://localhost:8000/listings/', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(formData),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      console.log('Listing created successfully:', result);
      // Optionally reset form
      setTitle('');
      setDescription('');
      setCashPrice('');
      setExchange('');
      setCategory('');
      setImageUrl('');
      setTradeType('mixed');
    } catch (error) {
      console.error('Error creating listing:', error);
    }
  };

  return (
    <Box sx={{ maxWidth: '800px', margin: 'auto', padding: 4 }}>
      <Typography variant="h5" component="h3" sx={{ mb: 4, fontWeight: 'bold' }}>
        Trade Type
      </Typography>
      <MuiGrid container spacing={2} sx={{ mb: 4 }}>
        {(['barter', 'cash', 'mixed'] as const).map((type) => (
          <MuiGrid
            key={type}
            component="div"
            sx={{
              gridColumn: { xs: 'span 12', sm: 'span 4' },
            }}
          >
            <TradeTypeButton
              selected={tradeType === type}
              onClick={() => setTradeType(type)}
              fullWidth
            >
              <Box>
                <Typography variant="h4" component="div" sx={{ mb: 1 }}>
                  {type === 'barter' && '🔄'}
                  {type === 'cash' && '💰'}
                  {type === 'mixed' && '🔀'}
                </Typography>
                <Typography variant="h6" component="div" sx={{ textTransform: 'capitalize' }}>
                  {type}
                </Typography>
                <Typography variant="body2" color="text.secondary">
                  {type === 'barter' && 'Trade items only'}
                  {type === 'cash' && 'Sell for cash only'}
                  {type === 'mixed' && 'Cash + items'}
                </Typography>
              </Box>
            </TradeTypeButton>
          </MuiGrid>
        ))}
      </MuiGrid>

      <form onSubmit={handleSubmit}>
        <MuiGrid container spacing={4}>
          <MuiGrid
            component="div"
            sx={{
              gridColumn: { xs: 'span 12', md: 'span 6' },
            }}
          >
            <TextField
              label="Title"
              fullWidth
              placeholder="e.g., Samsung Galaxy S21"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
            />
          </MuiGrid>
          <MuiGrid
            component="div"
            sx={{
              gridColumn: { xs: 'span 12' },
            }}
          >
            <TextField
              label="Description"
              multiline
              rows={4}
              fullWidth
              placeholder="Describe your item in detail..."
              value={description}
              onChange={(e) => setDescription(e.target.value)}
            />
          </MuiGrid>
          {tradeType !== 'barter' && (
            <MuiGrid
              component="div"
              sx={{
                gridColumn: { xs: 'span 12', md: 'span 6' },
              }}
            >
              <TextField
                label="Cash Price (KES)"
                type="number"
                fullWidth
                placeholder="5000"
                value={cashPrice}
                onChange={(e) => setCashPrice(e.target.value)}
                InputProps={{
                  startAdornment: <InputAdornment position="start">KES</InputAdornment>,
                }}
              />
            </MuiGrid>
          )}
          {tradeType !== 'cash' && (
            <MuiGrid
              component="div"
              sx={{
                gridColumn: { xs: 'span 12' },
              }}
            >
              <TextField
                label="What do you want in exchange?"
                multiline
                rows={4}
                fullWidth
                placeholder="List items you want to trade for..."
                value={exchange}
                onChange={(e) => setExchange(e.target.value)}
              />
            </MuiGrid>
          )}
          <MuiGrid
            component="div"
            sx={{
              gridColumn: { xs: 'span 12' },
            }}
          >
            <TextField
              label="Image URL"
              fullWidth
              placeholder="https://example.com/image.jpg"
              value={imageUrl}
              onChange={(e) => setImageUrl(e.target.value)}
            />
          </MuiGrid>
          <MuiGrid
            component="div"
            sx={{
              gridColumn: { xs: 'span 12', md: 'span 6' },
            }}
          >
            <FormControl fullWidth>
              <InputLabel>Category</InputLabel>
              <Select
                label="Category"
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                <MenuItem value="">Select category</MenuItem>
                <MenuItem value="electronics">Electronics</MenuItem>
                <MenuItem value="phones">Phones & Tablets</MenuItem>
                <MenuItem value="agriculture">Agriculture</MenuItem>
                <MenuItem value="services">Services</MenuItem>
              </Select>
            </FormControl>
          </MuiGrid>
        </MuiGrid>
        <Box sx={{ mt: 4 }}>
          <Button type="submit" variant="contained" size="large">
            Create Listing
          </Button>
        </Box>
      </form>
    </Box>
  );
}