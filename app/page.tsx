"use client";

import { Box, Typography, Button } from "@mui/material";
import CreateListingFormMui from "@/components/forms/CreateListingFormMui";
import ListingGrid from "@/components/listings/ListingGrid"; // Import ListingGrid
import { Listing } from "@/components/listings/ListingCard"; // Import Listing interface

const mockListings: Listing[] = [
  { id: 1, title: "Vintage Camera", price: "$150", imageUrl: "https://via.placeholder.com/300x200?text=Vintage+Camera" },
  { id: 2, title: "Handmade Pottery", price: "$45", imageUrl: "https://via.placeholder.com/300x200?text=Handmade+Pottery" },
  { id: 3, title: "Rare Comic Book", price: "$75", imageUrl: "https://via.placeholder.com/300x200?text=Comic+Book" },
  { id: 4, title: "Custom Artwork", price: "$200", imageUrl: "https://via.placeholder.com/300x200?text=Custom+Artwork" },
  { id: 5, title: "Antique Watch", price: "$300", imageUrl: "https://via.placeholder.com/300x200?text=Antique+Watch" },
  { id: 6, title: "Classic Vinyl Player", price: "$120", imageUrl: "https://via.placeholder.com/300x200?text=Vinyl+Player" },
];

export default function Home() {
  return (
    <Box>
      {/* Hero Section */}
      <Box
        sx={{
          minHeight: "400px",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          alignItems: "center",
          textAlign: "center",
          backgroundColor: "primary.main",
          color: "white",
          p: 4,
          mb: 4,
          backgroundImage: "url('https://source.unsplash.com/random/1920x400?commerce,exchange')", // Subtle background image
          backgroundSize: "cover",
          backgroundPosition: "center",
          backgroundBlendMode: "overlay", // Blend with background color
        }}
      >
        <Typography variant="h2" component="h1" gutterBottom>
          Discover & Barter Unique Items
        </Typography>
        <Typography variant="h5" component="p" sx={{ mb: 3 }}>
          Exchange goods and services with a vibrant community. Find what you need, offer what you have.
        </Typography>
        <Button variant="contained" color="secondary" size="large">
          Start Trading
        </Button>
      </Box>

      {/* Featured Listings Section */}
      <Box sx={{ p: 4 }}>
        <Typography variant="h4" component="h2" gutterBottom align="center" sx={{ mb: 4 }}>
          Featured Listings
        </Typography>
        <ListingGrid listings={mockListings} />
      </Box>

      {/* Optionally keep the form or move it elsewhere */}
      {/* <CreateListingFormMui /> */}
    </Box>
  );
}
