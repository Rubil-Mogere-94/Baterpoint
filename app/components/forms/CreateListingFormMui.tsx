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

  return (
    <Box sx={{ maxWidth: '800px', margin: 'auto', padding: 4 }}>
      <Typography variant="h5" component="h3" sx={{ mb: 4, fontWeight: 'bold' }}>
        Trade Type
      </Typography>
      <MuiGrid container spacing={2} sx={{ mb: 4 }}>
        {(['barter', 'cash', 'mixed'] as const).map((type) => (
          // @ts-ignore
          <MuiGrid item xs={12} sm={4} key={type}>
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

      <MuiGrid container spacing={4}>
        {/* @ts-ignore */}
        <MuiGrid item xs={12} md={6}>
          <TextField
            label="Title"
            fullWidth
            placeholder="e.g., Samsung Galaxy S21"
          />
        </MuiGrid>
        {tradeType !== 'barter' && (
          // @ts-ignore
          <MuiGrid item xs={12} md={6}>
            <TextField
              label="Cash Price (KES)"
              type="number"
              fullWidth
              placeholder="5000"
              InputProps={{
                startAdornment: <InputAdornment position="start">KES</InputAdornment>,
              }}
            />
          </MuiGrid>
        )}
        {tradeType !== 'cash' && (
          // @ts-ignore
          <MuiGrid item xs={12}>
            <TextField
              label="What do you want in exchange?"
              multiline
              rows={4}
              fullWidth
              placeholder="List items you want to trade for..."
            />
          </MuiGrid>
        )}
        {/* @ts-ignore */}
        <MuiGrid item xs={12} md={6}>
          <FormControl fullWidth>
            <InputLabel>Category</InputLabel>
            <Select label="Category">
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
        <Button variant="contained" size="large">
          Create Listing
        </Button>
      </Box>
    </Box>
  );
}