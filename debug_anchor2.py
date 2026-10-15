with open('frontend/lib/screens/cart/cart_screen.dart') as f:
    content = f.read()

# Check what the actual variable contains in the patch
anchor = "subtitle: Text('\$quantity × \\\$${price.toStringAsFixed(2)}'),"
print('Anchor:', repr(anchor))
print('In content:', anchor in content)

# Show the exact line
for line in content.split('\n'):
    if 'quantity' in line and 'price' in line and 'subtitle' in line:
        print('Line:', repr(line))