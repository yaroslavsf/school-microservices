import Fastify from 'fastify';

const app = Fastify({ logger: true });

app.get('/', async () => {
  return { hello: 'world' };
});

await app.listen({ port: 3000 });