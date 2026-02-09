import '@testing-library/jest-dom/extend-expect';
import { TextEncoder, TextDecoder } from 'util'; // Re-add this if it was removed
const fetch = require('node-fetch');


global.TextEncoder = TextEncoder;
global.TextDecoder = TextDecoder as any;
global.fetch = fetch;
global.Response = fetch.Response;
global.Request = fetch.Request;
global.Headers = fetch.Headers;