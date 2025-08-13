<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class BeemSmsService
{
    protected $apiKey;
    protected $secretKey;
    protected $senderName;
    protected $endpoint;

    public function __construct()
    {
        $this->apiKey = config('services.beem.api_key');
        $this->secretKey = config('services.beem.secret_key');
        $this->senderName = config('services.beem.sender_name');
        $this->endpoint = 'https://apisms.beem.africa/v1/send';
    }

    /**
     * Send an SMS message.
     *
     * @param string $recipient
     * @param string $message
     * @return bool
     */
    /**
     * Formats a phone number to E.164 format (e.g., 2557XXXXXXXX).
     *
     * @param string $phoneNumber
     * @return string
     */
    protected function formatPhoneNumber($phoneNumber)
    {
        // Remove any non-digit characters
        $phoneNumber = preg_replace('/[^0-9]/', '', $phoneNumber);

        // If it starts with 0, replace with 255
        if (substr($phoneNumber, 0, 1) === '0') {
            return '255' . substr($phoneNumber, 1);
        }
        // If it doesn't start with 255, assume it's a local number and prepend 255
        else if (substr($phoneNumber, 0, 3) !== '255') {
            return '255' . $phoneNumber;
        }

        return $phoneNumber;
    }

    public function sendSms($recipient, $message)
    {
        if (!$this->apiKey || !$this->secretKey) {
            Log::error('Beem SMS API key or secret key is not configured.');
            return false;
        }

        // Format the recipient number to E.164
        $formattedRecipient = $this->formatPhoneNumber($recipient);

        try {
            $response = Http::withBasicAuth($this->apiKey, $this->secretKey)
                ->post($this->endpoint, [
                    'source_addr' => $this->senderName,
                    'encoding' => 0,
                    'message' => $message,
                    'recipients' => [
                        [
                            'recipient_id' => rand(100000, 999999),
                            'dest_addr' => $formattedRecipient,
                        ]
                    ],
                ]);

            if ($response->successful()) {
                Log::info('SMS sent successfully to ' . $recipient);
                return true;
            }

            Log::error('Failed to send SMS to ' . $recipient . '. Status: ' . $response->status() . '. Response: ' . $response->body());
            return false;

        } catch (\Exception $e) {
            Log::error('Exception while sending SMS to ' . $recipient . ': ' . $e->getMessage());
            return false;
        }
    }
}
