import { Container, Typography } from "@mui/material";

export default function Home() {
  return (
    <Container>
      <Typography variant="h1" component="h1" gutterBottom>
        Welcome to BarterPoint
      </Typography>
      <Typography variant="body1">
        Trade goods and services across Kenya
      </Typography>
    </Container>
  );
}
