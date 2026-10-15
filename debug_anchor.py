with open('frontend/lib/screens/cart/cart_screen.dart') as f:
    content = f.read()

# Find the exact anchor
anchor = r"subtitle: Text('\$quantity × \$${price.toStringAsFixed(2)}'),"
print('Anchor:', repr(anchor))
print('Count:', content.count(anchor))

# Try with different escaping
anchor2 = "subtitle: Text('\$quantity × \\$${price.toStringAsFixed(2)}'),"
print('Anchor2:', repr(anchor2))
print('Count2:', content.count(anchor2))

# Actual line from file
for i, line in enumerate(content.split('\n'), 1):
    if 'quantity' in line and 'price' in line and 'subtitle' in line:
        print(f'Line {i}: {repr(line)}')