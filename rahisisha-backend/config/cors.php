<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'storage/*'],

    'allowed_methods' => ['*'],

    // ****** TEMPORARY SOLUTION FOR DEBUGGING ******
    // Allows requests from any origin.
    // REMEMBER TO CHANGE THIS BACK TO SPECIFIC ORIGINS FOR PRODUCTION!
    'allowed_origins' => [
    'https://fortex.co.tz',
    'https://derrickabsalom.com',
    'https://bizmax.co.tz',
    'http://bizmax.co.tz',
    'http://localhost:*',
],


    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => false,
];