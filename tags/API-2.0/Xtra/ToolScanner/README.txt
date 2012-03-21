
A script that runs a simple sanity on a XRNX tool. It's meant to help a human
admin and is by no means exhaustive.

# Example usage:

require('scanner');
$result = scan('/path/to/com.renoise.Duplex.xrnx');
if ($result !== true) {
  echo "Warnings Found: " . count($result) . "\n";
  print_r($result);
}

# Can also be invoked with:

$ php run.php /path/to/file