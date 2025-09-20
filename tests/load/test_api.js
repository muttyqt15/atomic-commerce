import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

// Custom metrics to track failures
const raceConditionFailures = new Rate('race_condition_failures');
const stockExhaustedRate = new Rate('stock_exhausted_rate');
const successfulCheckouts = new Rate('successful_checkouts');

export let options = {
    scenarios: {
        // Scenario 1: High concurrency race condition test
        race_condition_test: {
            executor: 'constant-arrival-rate',
            rate: 50, // 50 requests per second
            timeUnit: '1s',
            duration: '30s',
            preAllocatedVUs: 100,
            maxVUs: 200,
        },

        // Scenario 2: Burst test to simulate real traffic spikes
        burst_test: {
            executor: 'ramping-arrival-rate',
            startRate: 10,
            timeUnit: '1s',
            preAllocatedVUs: 50,
            maxVUs: 100,
            stages: [
                { duration: '10s', target: 10 },
                { duration: '5s', target: 100 }, // Sudden spike
                { duration: '10s', target: 100 },
                { duration: '5s', target: 10 },
            ],
            startTime: '35s', // Start after race condition test
        }
    },

    thresholds: {
        http_req_duration: ['p(95)<500'], // 95% of requests under 500ms
        http_req_failed: ['rate<0.1'],    // Less than 10% failures
        race_condition_failures: ['rate<0.05'], // Less than 5% race condition failures
    },
};

// Test configuration - UPDATE THESE VALUES
const BASE_URL = 'http://localhost:8080'; // Your API base URL
const TEST_PRODUCT_ID = '8a6624d3-916a-480c-94ab-21b2dc9925d7'; // Product with known stock
const TEST_USER_ID = '38fca0ee-e9d4-4ace-8a0d-e0a966813b74';       // Valid user UUID
const EXPECTED_INITIAL_STOCK = 100; // Set this to your product's initial stock

export default function() {
    const payload = JSON.stringify({
        userId: TEST_USER_ID,
        productId: TEST_PRODUCT_ID,
        quantity: 1, // Try to buy 1 item each time
    });

    const params = {
        headers: {
            'Content-Type': 'application/json',
        },
        timeout: '10s',
    };

    const response = http.post(`${BASE_URL}/checkout`, payload, params);

    // Check response status and content
    const isSuccess = check(response, {
        'status is 200': (r) => r.status === 200,
        'response time < 2000ms': (r) => r.timings.duration < 2000,
        'has success message': (r) => {
            try {
                const body = JSON.parse(r.body);
                return body.message === 'Checkout successful' || body.message === 'Order already processed';
            } catch (e) {
                return false;
            }
        },
    });

    // Track different types of responses
    if (response.status === 200) {
        successfulCheckouts.add(1);
        try {
            const body = JSON.parse(response.body);
            if (body.duplicate === true) {
                console.log(`Duplicate order detected: ${body.order_id}`);
            }
        } catch (e) {
            // Ignore JSON parsing errors for metrics
        }
    } else if (response.status === 400) {
        try {
            const body = JSON.parse(response.body);
            if (body.error === 'Not enough stock') {
                stockExhaustedRate.add(1);
                console.log('Stock exhausted - this is expected');
            } else {
                console.log(`Bad request: ${body.error}`);
            }
        } catch (e) {
            console.log(`Bad request with unparseable body: ${response.body}`);
        }
    } else {
        raceConditionFailures.add(1);
        console.log(`Potential race condition failure - Status: ${response.status}, Body: ${response.body}`);
    }

    // Small delay to prevent overwhelming the server
    sleep(0.1);
}

export function setup() {
    console.log('=== K6 CHECKOUT RACE CONDITION TEST ===');
    console.log(`Testing endpoint: ${BASE_URL}/checkout`);
    console.log(`Product ID: ${TEST_PRODUCT_ID}`);
    console.log(`User ID: ${TEST_USER_ID}`);
    console.log(`Expected initial stock: ${EXPECTED_INITIAL_STOCK}`);
    console.log('');
    console.log('This test will:');
    console.log('1. Send concurrent checkout requests');
    console.log('2. Try to expose race conditions in stock checking');
    console.log('3. Measure how many requests succeed vs fail');
    console.log('4. Show duplicate order handling');
    console.log('');
    console.log('Expected behavior with race conditions:');
    console.log('- More orders created than available stock');
    console.log('- Database constraint violations');
    console.log('- Inconsistent stock levels');
    console.log('=====================================');

    // Verify the endpoint is reachable
    const healthCheck = http.get(`${BASE_URL}/health`);
    if (healthCheck.status !== 200) {
        console.warn(`Warning: Health check failed. Status: ${healthCheck.status}`);
    }

    return { startTime: new Date() };
}

export function teardown(data) {
    console.log('');
    console.log('=== TEST COMPLETED ===');
    console.log(`Test duration: ${(new Date() - data.startTime) / 1000}s`);
    console.log('');
    console.log('ANALYSIS TIPS:');
    console.log('1. Check your database - count actual orders created');
    console.log('2. Verify final stock level vs expected');
    console.log('3. Look for database errors in server logs');
    console.log('4. Race conditions will show as:');
    console.log('   - More orders than initial stock');
    console.log('   - Negative stock values');
    console.log('   - Database constraint violations');
    console.log('');
    console.log('SQL to check results:');
    console.log(`SELECT COUNT(*) as total_orders FROM orders WHERE product_id = '${TEST_PRODUCT_ID}';`);
    console.log(`SELECT stock FROM products WHERE id = '${TEST_PRODUCT_ID}';`);
    console.log('======================');
}

// Additional scenario for testing idempotency specifically
export function idempotencyTest() {
    const payload = JSON.stringify({
        userId: TEST_USER_ID,
        productId: TEST_PRODUCT_ID,
        quantity: 5,
    });

    const params = {
        headers: { 'Content-Type': 'application/json' },
    };

    // Send the same request multiple times rapidly
    for (let i = 0; i < 5; i++) {
        const response = http.post(`${BASE_URL}/checkout`, payload, params);
        console.log(`Idempotency test ${i + 1}: Status ${response.status}`);
    }
}