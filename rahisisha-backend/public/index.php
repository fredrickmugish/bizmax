<?php

use Illuminate\Contracts\Http\Kernel; // IMPORTANT: Notice 'Contracts\Http\Kernel'
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

/*
|--------------------------------------------------------------------------
| Check If The Application Is Under Maintenance
|--------------------------------------------------------------------------
|
| If the application is in maintenance mode / "down" we will render a simple
| activity page that quietly tells the user that the site is temporarily
| unavailable. This is rendered before any other service providers are
| loaded and allows us to tokenize the application channels and queues.
|
*/

if (file_exists($maintenance = __DIR__.'/../storage/framework/maintenance.php')) {
    require $maintenance;
}

/*
|--------------------------------------------------------------------------
| Register The Auto Loader
|--------------------------------------------------------------------------
|
| Composer provides a convenient, auto-load tool for our application. We
| just need to utilize it! We'll simply require it into the script here
| so we don't have to worry about the loading of any our classes. In
| addition, we'll set the a safe default for PHP's date timezone.
|
*/

require __DIR__.'/../vendor/autoload.php';

/*
|--------------------------------------------------------------------------
| Run The Application
|--------------------------------------------------------------------------
|
| The first thing we will do is create a new Laravel application instance
| which is the actual shell for the application that contains all of the
| components from the framework and the kernel that will handle incoming
| requests from this application into a web response.
|
*/

$app = require_once __DIR__.'/../bootstrap/app.php';

/*
|--------------------------------------------------------------------------
| Bind Important Interfaces
|--------------------------------------------------------------------------
|
| Next, we need to bind some important interfaces into the container so
| we will be able to resolve them when needed. The kernels serve the
| incoming requests to this application from both the web and CLI.
|
*/

$kernel = $app->make(Kernel::class); // <-- This line creates the HTTP Kernel instance

/*
|--------------------------------------------------------------------------
| Handle The Incoming Request
|--------------------------------------------------------------------------
|
| Once we have the application instance, we can handle the incoming request
| through the kernel, and send the associated response back to the client
| from this terminal. Let's go!
|
*/

$response = $kernel->handle( // <-- The request is now processed by the Kernel
    $request = Request::capture()
);

$response->send(); // <-- Response is sent

$kernel->terminate($request, $response); // <-- Kernel terminates the request