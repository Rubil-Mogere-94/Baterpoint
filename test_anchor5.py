# Test the full anchor
anchor = "subtitle: Text('$quantity × \\$${price.toStringAsFixed(2)}'),"
print('Anchor:', repr(anchor))

with open('frontend/lib/screens/cart/cart_screen.dart') as f:
    content = f.read()

print('In content:', anchor in content)
print('Count:', content.count(anchor))

# Also test the total anchor
anchor2 = "Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),"
print('Anchor2:', repr(anchor2))
print('In content:', anchor2 in content)

for line in content.split('\n'):
    if 'total.toStringAsFixed' in line:
        print('Line2:', repr(line))