package io.boot2prod.spring_app_deploy;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.SneakyThrows;
import org.assertj.core.api.Assertions;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.client.RestClient;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class SpringAppDeployApplicationTests {
    @LocalServerPort
    private int port;

    @Autowired
    private RestClient.Builder restClientBuilder;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void contextLoads() {}

    @SneakyThrows
    @Test
    void healthEndpointIsExposed() {
        RestClient restClient =
                restClientBuilder.baseUrl("http://localhost:" + port).build();
        ResponseEntity<String> resp = restClient
                .get()
                .uri("http://localhost:" + port + "/actuator/health")
                .retrieve()
                .toEntity(String.class);
        Assertions.assertThat(resp.getStatusCode().is2xxSuccessful()).isTrue();
        JsonNode node = objectMapper.readTree(resp.getBody());
        Assertions.assertThat(node.get("status").asText()).isEqualTo("UP");
    }
}
