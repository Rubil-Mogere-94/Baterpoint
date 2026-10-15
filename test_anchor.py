# Test the anchor
anchor_raw = r"subtitle: Text('\$quantity × \$${price.toStringAsFixed(2)}'),"
print('Raw anchor:', repr(anchor_raw))

anchor_reg = "subtitle: Text('\$quantity × \\$${price.toStringAsFixed(2)}'),"
print('Reg anchor:', repr(anchor_reg))

with open('frontend/lib/screens/cart/cart_screen.dart') as f:
    content = f.read()

print('Raw in content:', anchor_raw in content)
print('Reg in content:', anchor_reg in content)

for line in content.split('\n'):
    if 'quantity' in line and 'price' in line and 'subtitle' in line:
        print('Line:', repr(line))