<?php
$api = "";
$servers = array(
	"bhopeasy" => "localhost:4318",
	"bhophard" => "localhost:4318",
	"surfmain" => "localhost:4318"
);

function testValidity($anchor)
{
	if (ctype_alpha($anchor))
		return array("Result" => true, "Query" => "/" . $anchor);
	else
	{
		if (stristr($anchor, "!") !== false)
			return array("Result" => true, "Query" => "/" . $anchor);
	}
	
	return array("Result" => false);
}

if (isset($_GET["server"]))
{
	if (!$servers[$_GET["server"]])
	{
		echo "Invalid server";
		return;
	}
	
	$domain = $servers[$_GET["server"]];
	$split = explode(":", $domain);
	$url = $split[0];
	$port = $split[1];
	
	if (isset($_GET["anchor"]))
	{
		$validity = testValidity($_GET["anchor"]);
		if ($validity["Result"])
			$url .= $validity["Query"];
	}
	
	$curl = curl_init($url);
	curl_setopt($curl, CURLOPT_PORT, $port);
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($curl, CURLOPT_TIMEOUT, 3);
	
	$result = curl_exec($curl);
	$err = curl_errno($curl);
	curl_close($curl);
	
	if ($err == 0)
		echo $result;
	else
		echo "An error occurred while fetching the data (0x00" . ($err * 16) . ")";
}
elseif (isset($_GET["resolve"]))
{
	$resolve = $_GET["resolve"];
	$url = "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=$api&steamids=$resolve";
	
	$curl = curl_init($url);
	curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt($curl, CURLOPT_TIMEOUT, 3);
	
	$data = curl_exec($curl);
	$err = curl_errno($curl);
	curl_close($curl);
	
	if ($err == 0)
		echo $data;
	else
		echo "{}";
}
else
	echo "Invalid fetch request";
?>