import {
  createTheme,
  ThemeProvider,
  CssBaseline,
} from "@mui/material";
import Navigation from "@/components/Navigation";

const theme = createTheme({
  palette: {
    primary: {
      main: "#003366", // Darker, more professional blue (similar to Amazon's branding)
    },
    secondary: {
      main: "#FF9900", // Vibrant orange (Amazon's signature orange)
    },
    text: {
      primary: "#000000",
    },
    background: {
      default: "#ffffff",
      paper: "#f6f6f6",
    },
  },
});

export default function Layout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Navigation />
      <main>{children}</main>
    </ThemeProvider>
  );
}
