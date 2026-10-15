# Test the anchor - need no backslash before first $
anchor = "subtitle: Text('\$quantity × \\\$${price.toStringAsFixed(2)}'),"
print('Anchor:', repr(anchor))

with open('frontend/lib/screens/cart/cart_screen.dart') as f:
    content = f.read()

print('In content:', anchor in content)

for line in content.split('\n'):
    if 'quantity' in line and 'price' in line and 'subtitle' in line:
        print('Line:', repr(line))